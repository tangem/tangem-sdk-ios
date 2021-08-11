//
//  SignCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Response for `SignCommand`.
public struct SignResponse: JSONStringConvertible {
    /// CID, Unique Tangem card ID number
    public let cardId: String
    /// Signed hashes (array of resulting signatures)
    public let signatures: [Data]
    /// Total number of signed  hashes returned by the wallet since its creation. COS: 1.16+
    public let totalSignedHashes: Int?
}

/// Signs transaction hashes using a wallet private key, stored on the card.
@available(iOS 13.0, *)
class SignCommand: Command {
    
    var preflightReadMode: PreflightReadMode { .readWallet(publicKey: walletPublicKey) }
    
    var requiresPasscode: Bool { return true }
    
    private let walletPublicKey: Data
    private let hdPath: DerivationPath?
    private let hashes: [Data]
    
    private var signatures: [Data] = []
    
    private var currentChunkNumber: Int {
        signatures.count / chunkSize
    }
    private lazy var chunkSize: Int = {
        return NFCUtils.isPoorNfcQualityDevice ? 2 : 10
    }()
    private lazy var numberOfChunks: Int = {
        return stride(from: 0, to: hashes.count, by: chunkSize).underestimatedCount
    }()
    
    /// Command initializer
    /// - Parameters:
    ///   - hashes: Array of transaction hashes.
    ///   - walletPublicKey: Public key of the wallet, using for sign.
    ///   - hdPath: Derivation path of the wallet. Optional. COS v. 4.28 and higher,
    init(hashes: [Data], walletPublicKey: Data, hdPath: DerivationPath? = nil) {
        self.hashes = hashes
        self.walletPublicKey = walletPublicKey
        self.hdPath = hdPath
    }
    
    deinit {
        Log.debug("SignCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        guard let wallet = card.wallets[walletPublicKey] else {
            return .walletNotFound
        }
        
        if hdPath != nil {
            if card.firmwareVersion < .hdWalletAvailable {
                return .notSupportedFirmwareVersion
            }
            
            if wallet.curve != .secp256k1 {
                return .unsupportedCurve
            }
        }
        
        //Before v4
        if let remainingSignatures = wallet.remainingSignatures,
           remainingSignatures == 0 {
            return .noRemainingSignatures
        }
        
        if let defaultSigningMethods = card.settings.defaultSigningMethods {
            if !defaultSigningMethods.contains(.signHash) {
                return .signHashesNotAvailable
            }
        }
        
        if card.firmwareVersion.doubleValue < 2.28, card.settings.securityDelay > 15000 {
            return .oldCard
        }
        
        return nil
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<SignResponse>) {
        if hashes.count == 0 {
            completion(.failure(.emptyHashes))
            return
        }
        
        if hashes.contains(where: { $0.count != hashes.first!.count }) {
            completion(.failure(.hashSizeMustBeEqual))
            return
        }
        
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        let hasTerminalKeys = session.environment.terminalKeys != nil
        let hasEnoughDelay = (card.settings.securityDelay * numberOfChunks) <= 50000
        guard hashes.count <= chunkSize || (card.settings.isLinkedTerminalEnabled && hasTerminalKeys) || hasEnoughDelay else {
            completion(.failure(.tooManyHashesInOneTransaction))
            return
        }
        
        sign(in: session, completion: completion)
    }
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {        
        if case .unknownStatus = error {
            return .nfcStuck
        }
        
        return error
    }
    
    func sign(in session: CardSession, completion: @escaping CompletionResult<SignResponse>) {
        if numberOfChunks > 1 {
            session.viewDelegate.showAlertMessage("Signing part \(currentChunkNumber + 1) of \(numberOfChunks)")
        }
        
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                self.signatures.append(contentsOf: response.signatures)
                if self.signatures.count == self.hashes.count {
                    session.environment.card?.wallets[self.walletPublicKey]?.totalSignedHashes = response.totalSignedHashes
                    
                    if let remainingSignatures = session.environment.card?.wallets[self.walletPublicKey]?.remainingSignatures {
                        session.environment.card?.wallets[self.walletPublicKey]?.remainingSignatures = remainingSignatures - self.signatures.count
                    }
                    
                    completion(.success(SignResponse(cardId: response.cardId,
                                                     signatures: self.signatures,
                                                     totalSignedHashes: response.totalSignedHashes)))
                    return
                }
                
                session.restartPolling(silent: true)
                self.sign(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let flattenHashes = Data(hashes[getChunk()].joined())
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.pin2, value: environment.passcode.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.transactionOutHashSize, value: hashes.first!.count)
            .append(.transactionOutHash, value: flattenHashes)
            //Wallet index works only on COS v.4.0 and higher. For previous version index will be ignored
            .append(.walletPublicKey, value: walletPublicKey)
        
        if let cvc = environment.cvc {
            try tlvBuilder.append(.cvc, value: cvc)
        }
        
        /**
         * Application can optionally submit a public key Terminal_PublicKey in [SignCommand].
         * Submitted key is stored by the Tangem card if it differs from a previous submitted Terminal_PublicKey.
         * The Tangem card will not enforce security delay if [SignCommand] will be called with
         * TerminalTransactionSignature parameter containing a correct signature of raw data to be signed made with TerminalPrivateKey
         * (this key should be generated and securily stored by the application).
         * COS version 2.30 and later.
         */
        let isLinkedTerminalSupported = environment.card?.settings.isLinkedTerminalEnabled  ?? false
        if let keys = environment.terminalKeys, isLinkedTerminalSupported,
           let signedData = Secp256k1Utils.sign(flattenHashes, with: keys.privateKey) {
            try tlvBuilder
                .append(.terminalTransactionSignature, value: signedData)
                .append(.terminalPublicKey, value: keys.publicKey)
        }
        
        if let hdPath = self.hdPath {
            try tlvBuilder.append(.walletHDPath, value: hdPath)
        }
        
        return CommandApdu(.sign, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SignResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        let splittedSignatures = splitSignedSignature(try decoder.decode(.walletSignature), numberOfSignatures: getChunk().underestimatedCount)
        let resp = SignResponse(cardId: try decoder.decode(.cardId),
                                signatures: splittedSignatures,
                                totalSignedHashes: try decoder.decode(.walletSignedHashes))
        return resp
    }
    
    private func getChunk() -> Range<Int> {
        let from = currentChunkNumber * chunkSize
        let to = min(from + chunkSize, hashes.count)
        return from..<to
    }
    
    private func splitSignedSignature(_ signature: Data, numberOfSignatures: Int) -> [Data] {
        var signatures = [Data]()
        let signatureSize = signature.count / numberOfSignatures
        for index in 0..<numberOfSignatures {
            let offsetMin = index * signatureSize
            let offsetMax = offsetMin + signatureSize
            
            let sig = signature[offsetMin..<offsetMax]
            signatures.append(sig)
        }
        
        return signatures
    }
}
