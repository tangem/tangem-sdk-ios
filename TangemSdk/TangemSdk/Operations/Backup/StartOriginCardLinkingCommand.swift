//
//  StartOriginCardLinkingCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Response from the Tangem card after `StartOriginCardLinkingCommand`.
@available(iOS 13.0, *)
struct StartOriginCardLinkingResponse {
    /// Unique Tangem card ID number
    let cardId: String
    /// Card public key
    let cardPublicKey: Data
    /// Linking key
    let linkingKey: Data
}

@available(iOS 13.0, *)
final class StartOriginCardLinkingCommand: Command {
    var requiresPasscode: Bool { return false }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if !card.settings.isBackupAllowed {
            return .backupCannotBeCreated
        }
        
        if card.wallets.isEmpty {
            return .backupCannotBeCreatedEmptyWallets
        }
        
        return nil
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<StartOriginCardLinkingResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                guard let cardPublicKey = session.environment.card?.cardPublicKey else {
                    completion(.failure(.missingPreflightRead))
                    return
                }
                
                completion(.success(.init(cardId: response.cardId,
                                          cardPublicKey: cardPublicKey,
                                          linkingKey: response.linkingKey)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.cardId, value: environment.card?.cardId)
        
        return CommandApdu(.startOriginCardLinking, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> StartOriginCardLinkingResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        guard let cardPublicKey = environment.card?.cardPublicKey else {
            throw TangemSdkError.unknownError
        }
        
        return StartOriginCardLinkingResponse(cardId: try decoder.decode(.cardId),
                                              cardPublicKey: cardPublicKey,
                                              linkingKey: try decoder.decode(.originCardLinkingKey))
    }
}
