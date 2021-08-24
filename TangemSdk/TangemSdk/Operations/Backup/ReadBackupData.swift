//
//  ReadBackupData.swift
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
    let encryptedData: Data
    let encryptionSalt: Data
}

@available(iOS 13.0, *)
final class ReadBackupDataCommand: Command {
    var requiresPasscode: Bool { return false }
    
    private let backupSession: BackupSession
    private let slaveBackupKey: Data
    
    init(backupSession: BackupSession, slaveBackupKey: Data) {
        self.backupSession = backupSession
        self.slaveBackupKey = slaveBackupKey
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.backupStatus == .noBackup {
            return .backupCannotBeCreated
        }
        
        if backupSession.master.cardKey != card.cardPublicKey {
            return .backupMasterCardRequired
        }
        
        return nil
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.pin, value: environment.accessCode.value)
            .append(.backupSlaveKey, value: slaveBackupKey)
        
        return CommandApdu(.backupReadData, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadBackupDataResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        return ReadBackupDataResponse(cardId: try decoder.decode(.cardId),
                                      encryptedData: try decoder.decode(.issuerData),
                                      encryptionSalt: try decoder.decode(.salt))
    }
}

