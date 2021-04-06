//
//  SignCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

extension Array: JSONStringConvertible where Element == Data  {}

/// Signs transaction hashes using a wallet private key, stored on the card.
public final class SignCommand: Command {
    public typealias CommandResponse = [Data]
    
    public var requiresPin2: Bool {
        return true
    }
    
    public var preflightReadSettings: PreflightReadSettings {
        .readWallet(index: walletIndex)
    }
    
    private let walletIndex: WalletIndex
    private let hashes: [Data]
    private var responces: [Data] = []
    private var respondedSignature: Data = Data()
    private var currentChunk = 0
    private lazy var chunkSize: Int = {
        return NfcUtils.isPoorNfcQualityDevice ? 2 : 10
    }()
    private lazy var numberOfChunks: Int = {
        return stride(from: 0, to: hashes.count, by: chunkSize).underestimatedCount
    }()
    
	/// Command initializer
	/// - Note: Wallet index works only on COS v.4.0 and higher. For previous version index will be ignored
	/// - Parameters:
	///   - hashes: Array of transaction hashes.
	///   - walletIndex: Index to wallet for interaction.
	public init(hashes: [Data], walletIndex: WalletIndex) {
        self.hashes = hashes
		self.walletIndex = walletIndex
    }
    
    deinit {
        Log.debug("SignCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        guard card.status != .notPersonalized else {
            return .notPersonalized
        }
        
        if card.isActivated {
            return .notActivated
        }
        
        guard let wallet = card.wallet(at: walletIndex) else {
            return .walletNotFound
        }
        
        switch wallet.status {
        case .empty:
            return .cardIsEmpty
        case .loaded:
            break
        case .purged:
            return .cardIsPurged
        }
        
		if card.firmwareVersion < FirmwareConstraints.DeprecationVersions.walletRemainingSignatures,
           wallet.remainingSignatures == 0 {
            return .noRemainingSignatures
        }
        
        if let signingMethod = card.signingMethods, !signingMethod.contains(.signHash) {
            return .signHashesNotAvailable
        }
        
        return nil
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<[Data]>) {
        if hashes.count == 0 {
            completion(.failure(.emptyHashes))
            return
        }
        
        if hashes.contains(where: { $0.count != hashes.first!.count }) {
            completion(.failure(.hashSizeMustBeEqual))
            return
        }
        
        let isLinkedTerminalSupported = session.environment.card?.isLinkedTerminalSupported ?? false
        let hasTerminalKeys = session.environment.terminalKeys != nil
        let delay = session.environment.card?.pauseBeforePin2 ?? 3000
        let hasEnoughDelay = (delay * numberOfChunks) <= 5000
        guard hashes.count <= chunkSize || (isLinkedTerminalSupported && hasTerminalKeys) || hasEnoughDelay else {
            completion(.failure(.tooManyHashesInOneTransaction))
            return
        }
        
        sign(in: session, completion: completion)
    }
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        if case .invalidParams = error {
            return .pin2OrCvcRequired
        }
        
        if case .unknownStatus = error {
            return .nfcStuck
        }
        
        return error
    }
    
    func sign(in session: CardSession, completion: @escaping CompletionResult<[Data]>) {
        if currentChunk == numberOfChunks {
            do {
                let parsed = try SignatureParser.parseSignedSignature(respondedSignature)
                completion(.success(parsed))
                return
            } catch {
                completion(.failure(error as! TangemSdkError))
                return
            }
        }
        
        if numberOfChunks > 1 {
            session.viewDelegate.showAlertMessage("Signing part \(currentChunk + 1) of \(numberOfChunks)")
        }
        
        transieve(in: session) { result in
            switch result {
            case .success(let response):
                self.respondedSignature += response[0]
                self.currentChunk += 1
                if self.currentChunk != self.numberOfChunks {
                    session.restartPolling()
                }
                self.sign(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let flattenHashes = Data(hashes[getChunk()].joined())
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1.value)
            .append(.pin2, value: environment.pin2.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.transactionOutHashSize, value: hashes.first!.count)
            .append(.transactionOutHash, value: flattenHashes)
        
        /**
         * Application can optionally submit a public key Terminal_PublicKey in [SignCommand].
         * Submitted key is stored by the Tangem card if it differs from a previous submitted Terminal_PublicKey.
         * The Tangem card will not enforce security delay if [SignCommand] will be called with
         * TerminalTransactionSignature parameter containing a correct signature of raw data to be signed made with TerminalPrivateKey
         * (this key should be generated and securily stored by the application).
         * COS version 2.30 and later.
         */
        let isLinkedTerminalSupported = environment.card?.isLinkedTerminalSupported ?? false
        if let keys = environment.terminalKeys, isLinkedTerminalSupported,
            let signedData = Secp256k1Utils.sign(flattenHashes, with: keys.privateKey) {
            try tlvBuilder
                .append(.terminalTransactionSignature, value: signedData)
                .append(.terminalPublicKey, value: keys.publicKey)
        }
		
		try walletIndex.addTlvData(to: tlvBuilder)
        
        return CommandApdu(.sign, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> [Data] {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return [try decoder.decode(.walletSignature)]
    }
    
    private func getChunk() -> Range<Int> {
        let from = currentChunk * chunkSize
        let to = min(from + chunkSize, hashes.count)
        return from..<to
    }
}
