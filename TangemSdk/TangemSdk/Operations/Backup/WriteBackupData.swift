//
//  WriteBackupData.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

// Response from the Tangem card after `WriteBackupDataCommand`.
@available(iOS 13.0, *)
struct WriteBackupDataResponse {
    /// Unique Tangem card ID number
    let cardId: String
    let state: Card.BackupStatus
}

@available(iOS 13.0, *)
final class WriteBackupDataCommand: Command {
    var requiresPasscode: Bool { return false }
    
    private let backupSession: BackupSession
    
    init(backupSession: BackupSession) {
        self.backupSession = backupSession
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.backupStatus == .noBackup {
            return .backupCannotBeCreated
        }
        
        guard let card = backupSession.slaves[card.cardId] else {
            return .backupSlaveCardRequired
        }
        
        if card.encryptedData == nil {
            return .backupInvalidCommandSequence
        }
        
        return nil
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.pin, value: environment.accessCode.value)
            .append(.pin2, value: environment.passcode.value)
            .append(.salt, value: backupSession.slaves[environment.card!.cardId]!.encryptionSalt)
            .append(.issuerData, value: backupSession.slaves[environment.card!.cardId]!.encryptedData)
        
        return CommandApdu(.backupWriteData, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> WriteBackupDataResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        return WriteBackupDataResponse(cardId: try decoder.decode(.cardId),
                                       state: try decoder.decode(.backupStatus))
    }
}

