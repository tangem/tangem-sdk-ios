//
//  ReadWalletsListCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 16/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public struct ReadWalletsListResponse: JSONStringConvertible {
    public let cardId: String
    public let wallets: [CardWallet]
}

/// Read all wallets on card.
public class ReadWalletsListCommand: Command {
    public var preflightReadMode: PreflightReadMode { .readCardOnly }
    
    private var walletIndex: Int?
    private var loadedWallets: [CardWallet] = []
    
    public init() {}
    
    deinit {
        Log.debug("ReadWalletsListCommand deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<ReadWalletsListResponse>) {
        transieve(in: session) { result in
            switch result {
            case .success(let response):
                self.loadedWallets.append(contentsOf: response.wallets)
                let loadedWalletsCount = self.loadedWallets.count
                
                if loadedWalletsCount == 0 && response.wallets.count == 0 {
                    completion(.failure(.cardWithMaxZeroWallets))
                    return
                }
                
                guard loadedWalletsCount == session.environment.card?.walletsCount else {
                    self.walletIndex = loadedWalletsCount
                    self.run(in: session, completion: completion)
                    return
                }
                
                completion(.success(ReadWalletsListResponse(cardId: response.cardId,
                                                       wallets: self.loadedWallets)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1.value)
            .append(.interactionMode, value: ReadMode.readWalletList)
            .append(.cardId, value: environment.card?.cardId)
        
        if let keys = environment.terminalKeys {
            try tlvBuilder.append(.terminalPublicKey, value: keys.publicKey)
        }
        
        if let walletIndex = walletIndex {
            try tlvBuilder.append(.walletIndex, value: walletIndex)
        }
        
        return CommandApdu(.read, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadWalletsListResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        let wallets = try CardWalletDeserializer.deserializeWallets(from: decoder)
        return ReadWalletsListResponse(cardId: try decoder.decode(.cardId),
                                       wallets: wallets)
    }
}
