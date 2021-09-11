//
//  ReadWalletCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 16/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
struct ReadWalletResponse: JSONStringConvertible {
    let cardId: String
    let wallet: Card.Wallet
}

/// Read single wallet on card. This command executes before interacting with specific wallet to retrieve information about it and perform prechecks
@available(iOS 13.0, *)
class ReadWalletCommand: Command {
    
    var preflightReadMode: PreflightReadMode { .readCardOnly }
    
    private let walletPublicKey: Data
    private let hdPath: DerivationPath?
    
    init(publicKey: Data, hdPath: DerivationPath? = nil) {
        self.walletPublicKey = publicKey
        self.hdPath = hdPath
    }
    
    deinit {
        Log.debug("ReadWalletCommand deinit")
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<ReadWalletResponse>) {
        Log.debug("Attempt to read wallet with key: \(walletPublicKey)")
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                session.environment.card?.wallets = [response.wallet]
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.interactionMode, value: ReadMode.wallet)
            .append(.cardId, value: environment.card?.cardId)
            .append(.walletPublicKey, value: walletPublicKey)
        
        if let keys = environment.terminalKeys {
            try tlvBuilder.append(.terminalPublicKey, value: keys.publicKey)
        }
        
        if let hdPath = hdPath {
            try tlvBuilder.append(.walletHDPath, value:  hdPath)
        }
        
        return CommandApdu(.read, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadWalletResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        guard let card = environment.card else {
            throw TangemSdkError.unknownError
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        guard let wallet = try? WalletDeserializer(isDefaultPermanentWallet: card.settings.isPermanentWallet).deserializeWallet(from: decoder) else {
            throw TangemSdkError.walletNotFound
        }
        
        Log.debug("Read wallet: \(wallet)")
        return ReadWalletResponse(cardId: try decoder.decode(.cardId),
                                  wallet: wallet)
    }
}
