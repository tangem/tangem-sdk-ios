//
//  CreateWalletCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Response from the Tangem card after `CreateWalletCommand`.
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
 * WalletPrivateKey is never revealed by the card and will be used by `SignCommand` and `CheckWalletCommand`.
 * RemainingSignature is set to MaxSignatures.
 */
public final class CreateWalletCommand: Command {
    public typealias Response = CreateWalletResponse
    
    public var requiresPin2: Bool { return true }
    
    private let curve: EllipticCurve
    private var config: WalletConfig
    private var walletIndex: Int? = nil
    /// Default initializer
    /// - Parameter config: Wallet configuration to create
    /// - COS v4+: Wallet configuration or default wallet configuration according to card personalization if nil
    /// - COS before v4: This parameter can be ignored.  Wallet will be created according to card personalization.
    public init(curve: EllipticCurve, config: WalletConfig = .init()) {
        self.curve = curve
        self.config = config
    }
    
    deinit {
        Log.debug("CreateWalletCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion >= .multiwalletAvailable,
           !card.settings.mask.contains(.allowSelectBlockchain) {
            return .walletCannotBeCreated
        }
        
        guard card.supportedCurves.contains(curve) else {
            return TangemSdkError.unsupportedCurve
        }
        
        if card.firmwareVersion < FirmwareVersion.multiwalletAvailable {
            if let designatedIsProhibitPurge = config.isProhibitPurge {
                let currentIsProhibitPurge = card.settings.mask.contains(.prohibitPurgeWallet)
                if designatedIsProhibitPurge != currentIsProhibitPurge {
                    return TangemSdkError.unsupportedWalletConfig
                }
            }
            
            if let designatedSigningMethods = config.signingMethods {
                if designatedSigningMethods != card.settings.defaultSigningMethods {
                    return TangemSdkError.unsupportedWalletConfig
                }
            }
        }
        
        return nil
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        let maxIndex = card.settings.maxWalletsCount
        let occupiedIndexes = card.wallets.map { $0.index }
        let allIndexes = 0..<maxIndex
        if let firstAvailableIndex = allIndexes.filter({ !occupiedIndexes.contains($0) }).sorted().first {
            self.walletIndex = firstAvailableIndex
        } else {
            //already created for old cards mostly
            completion(.failure(maxIndex == 1 ? .alreadyCreated : .maxNumberOfWalletsCreated))
            return
        }
        
        transieve(in: session, completion: completion)
    }
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        if case .invalidParams = error {
            guard let card = card else { return error }
            
            if card.firmwareVersion >= .pin2IsDefaultAvailable,
               let pin2IsDefault = card.pin2IsDefault, pin2IsDefault {
                return .alreadyCreated
            }
        }
        
        return error
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1.value)
            .append(.pin2, value: environment.pin2.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.walletIndex, value: walletIndex)
        
        if let cvc = environment.cvc {
            try tlvBuilder.append(.cvc, value: cvc)
        }
        
        if environment.card?.firmwareVersion >= .multiwalletAvailable {
            if let settingsMask = config.settingsMask {
                try tlvBuilder.append(.settingsMask, value: settingsMask)
            }
            
            try tlvBuilder.append(.curveId, value: curve)
            
            if let signingMethods = config.signingMethods {
                try tlvBuilder.append(.signingMethod, value: signingMethods)
            }
        }
        
        return CommandApdu(.createWallet, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> CreateWalletResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        let index = try decoder.decodeOptional(.walletIndex) ?? walletIndex!
        
        guard let settingsMask = config.settingsMask ?? environment.card?.settings.mask.toWalletSettingsMask(),
              let signingMethods = config.signingMethods ?? environment.card?.settings.defaultSigningMethods else {
            throw TangemSdkError.unknownError
        }
        
        let walletSettings = Card.Wallet.Settings(mask: settingsMask,
                                                  signingMethods: signingMethods)
        
        let wallet = Card.Wallet(publicKey: try decoder.decode(.walletPublicKey),
                                 curve: curve,
                                 settings: walletSettings,
                                 totalSignedHashes: 0,
                                 remainingSignatures: environment.card?.remainingSignatures,
                                 index: index)
        
        return CreateWalletResponse(cardId: try decoder.decode(.cardId), wallet: wallet)
    }
}
