//
//  ReadBackupDataCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

// Response from the Tangem card after `ReadBackupDataCommand`.
@available(iOS 13.0, *)
struct ReadBackupDataResponse {
    /// Unique Tangem card ID number
    let cardId: String
    let data: EncryptedBackupData
}

@available(iOS 13.0, *)
final class ReadBackupDataCommand: Command {
    var requiresPasscode: Bool { return false }
    
    private let backupCardLinkingKey: Data
    private let accessCode: Data
    
    init(backupCardLinkingKey: Data, accessCode: Data) {
        self.backupCardLinkingKey = backupCardLinkingKey
        self.accessCode = accessCode
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
//        if card.backupStatus == .noBackup { //TODO: Actually we can skip this check. TBD
//            return .backupCannotBeCreated
//        }
        
        return nil
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<ReadBackupDataResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                if case let .cardLinked(cardsCount: cardsCount) = session.environment.card?.backupStatus {
                    session.environment.card?.backupStatus = .active(cardsCount: cardsCount)
                }
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.pin, value: accessCode)
            .append(.backupCardLinkingKey, value: backupCardLinkingKey)
        
        return CommandApdu(.readBackupData, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadBackupDataResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        return ReadBackupDataResponse(cardId: try decoder.decode(.cardId),
                                      data: EncryptedBackupData (data: try decoder.decode(.issuerData),
                                                                 salt: try decoder.decode(.salt)))
    }
}

