//
//  CreateWalletCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Response from the Tangem card after `CreateWalletCommand`.
@available(iOS 13.0, *)
public struct CreateWalletResponse: JSONStringConvertible {
    /// Unique Tangem card ID number
    public let cardId: String
    /// Created wallet
    public let wallet: Card.Wallet
}

/**
 * This command will create a new wallet on the card having ‘Empty’ state.
 * A key pair WalletPublicKey / WalletPrivateKey is generated and securely stored in the card.
 * App will need to obtain Wallet_PublicKey from the response of `CreateWalletCommand`or `ReadCommand`
 * and then transform it into an address of corresponding blockchain wallet
 * according to a specific blockchain algorithm.
 * WalletPrivateKey is never revealed by the card and will be used by `SignCommand` and `AttestWalletKeyCommand`.
 * RemainingSignature is set to MaxSignatures.
 */
@available(iOS 13.0, *)
public final class CreateWalletCommand: Command {
    var requiresPasscode: Bool { return true }
    
    private let curve: EllipticCurve
    private let signingMethod = SigningMethod.signHash
    
    private var walletIndex: Int? = nil
    /// Default initializer
    /// - Parameter curve: Elliptic curve of the wallet.  `Card.supportedCurves` contains all curves supported by the card
    public init(curve: EllipticCurve) {
        self.curve = curve
    }
    
    deinit {
        Log.debug("CreateWalletCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion >= .multiwalletAvailable,
           !card.settings.isSelectBlockchainAllowed {
            return .walletCannotBeCreated
        }
        
        guard card.supportedCurves.contains(curve) else {
            return TangemSdkError.unsupportedCurve
        }
        
        if card.firmwareVersion < FirmwareVersion.multiwalletAvailable {
            if let cardSigningMethods = card.settings.defaultSigningMethods,
               !signingMethod.isSubset(of: cardSigningMethods) {
                return TangemSdkError.unsupportedWalletConfig
            }
        }
        
        return nil
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                var wallets: [Card.Wallet] = session.environment.card?.wallets ?? []
                wallets.append(response.wallet)
                session.environment.card?.wallets = wallets.sorted(by: { $0.index < $1.index })
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        if case .invalidParams = error {
            guard let card = card else { return error }
            
            if card.firmwareVersion >= .isPasscodeStatusAvailable,
               let isPasscodeSet = card.isPasscodeSet, !isPasscodeSet {
                return .alreadyCreated
            }
        }
        
        return error
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.pin2, value: environment.passcode.value)
            .append(.cardId, value: environment.card?.cardId)
        
        if let cvc = environment.cvc {
            try tlvBuilder.append(.cvc, value: cvc)
        }
        
        guard let card = environment.card else {
            throw TangemSdkError.missingPreflightRead
        }
        
        
        if card.firmwareVersion >= .multiwalletAvailable {
            let maskBuilder = MaskBuilder<WalletSettingsMask>()
            maskBuilder.add(.isReusable)
            
            try tlvBuilder.append(.settingsMask, value: maskBuilder.build())
                .append(.curveId, value: curve)
                .append(.signingMethod, value: signingMethod)
            
            let maxIndex = card.settings.maxWalletsCount //We need to execute this wallet index calculation stuff only after precheck. Run fires only before precheck. And precheck will not fire if error handling disabled
            let occupiedIndexes = card.wallets.map { $0.index }
            let allIndexes = 0..<maxIndex
            if let firstAvailableIndex = allIndexes.filter({ !occupiedIndexes.contains($0) }).sorted().first {
                self.walletIndex = firstAvailableIndex
            } else {
                if maxIndex == 1 {
                    //already created for old cards mostly
                    throw TangemSdkError.alreadyCreated
                } else {
                    throw TangemSdkError.maxNumberOfWalletsCreated
                }
            }
            
            try tlvBuilder.append(.walletIndex, value: walletIndex)
        }
        
        return CommandApdu(.createWallet, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> CreateWalletResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        guard let card = environment.card else {
            throw TangemSdkError.unknownError
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        let index = try decoder.decode(.walletIndex) ?? walletIndex!
        
        let wallet = Card.Wallet(publicKey: try decoder.decode(.walletPublicKey),
                                 chainCode: try decoder.decode(.walletHDChain),
                                 curve: curve,
                                 settings: Card.Wallet.Settings(isPermanent: card.settings.isPermanentWallet),
                                 totalSignedHashes: 0,
                                 remainingSignatures: card.remainingSignatures,
                                 index: index,
                                 hasBackup: false)
        
        return CreateWalletResponse(cardId: try decoder.decode(.cardId), wallet: wallet)
    }
}
