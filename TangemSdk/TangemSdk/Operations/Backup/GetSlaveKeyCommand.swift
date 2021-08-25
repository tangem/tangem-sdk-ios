//
//  GetSlaveKeyCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation


/// Response from the Tangem card after `GetMasterKeyCommand`.
@available(iOS 13.0, *)
struct GetSlaveKeyResponse {
    /// Unique Tangem card ID number
    let cardId: String
    /// Session for backup
    let slave: BackupSlave
}

@available(iOS 13.0, *)
final class GetSlaveKeyCommand: Command {
    var requiresPasscode: Bool { return false }

    private let backupSession: BackupSession //todo: backupSession.master.backupKey
    
    init(backupSession: BackupSession) {
        self.backupSession = backupSession
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if !card.wallets.isEmpty || !card.settings.isBackupAllowed {
            return .backupCannotBeCreated
        }
        
        //todo: move to service?
        if backupSession.slaves.keys.contains(card.cardId) {
            return .backupSlaveCardAlreadyInList
        }
        
        return nil
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.backupMasterKey, value: backupSession.master.backupKey)
        
        return CommandApdu(.backupGetSlaveKey, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> GetSlaveKeyResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        guard let cardKey = environment.card?.cardPublicKey else {
            throw TangemSdkError.unknownError
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        let slave = BackupSlave(backupKey: try decoder.decode(.backupSlaveKey),
                                cardKey: cardKey,
                                attestSignature: try decoder.decode(.cardSignature))
        //todo: move to run
        let prefix = "BACKUP_SLAVE".data(using: .utf8)!
        let dataAttest = prefix + backupSession.master.backupKey + slave.backupKey
        let verified = try CryptoUtils.verify(curve: .secp256k1, publicKey: slave.cardKey, message: dataAttest, signature: slave.attestSignature)
        if !verified {
            throw TangemSdkError.backupInvalidSignature
        }
        //todo: refactor response
        return GetSlaveKeyResponse(cardId: try decoder.decode(.cardId),
                                   slave: slave)
    }
}
