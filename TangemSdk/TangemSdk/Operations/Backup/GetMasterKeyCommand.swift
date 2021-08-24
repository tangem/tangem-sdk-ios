//
//  GetMasterKeyCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Response from the Tangem card after `GetMasterKeyCommand`.
@available(iOS 13.0, *)
struct GetMasterKeyResponse {
    /// Unique Tangem card ID number
    let cardId: String
    /// Session for backup
    let master: BackupMaster
}

@available(iOS 13.0, *)
final class GetMasterKeyCommand: Command {
    var requiresPasscode: Bool { return false }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.wallets.isEmpty || !card.settings.isBackupAllowed {
            return .backupCannotBeCreated
        }
        
        return nil
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.cardId, value: environment.card?.cardId)
        
        return CommandApdu(.backupGetMasterKey, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> GetMasterKeyResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        guard let cardKey = environment.card?.cardPublicKey else {
            throw TangemSdkError.unknownError
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        let master = BackupMaster(backupKey: try decoder.decode(.backupMasterKey),
                                  cardKey: cardKey)
        
        return GetMasterKeyResponse(cardId: try decoder.decode(.cardId),
                                    master: master)
    }
}
