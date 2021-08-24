//
//  LinkMasterCard.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

// Response from the Tangem card after `LinkMasterCardCommand`.
@available(iOS 13.0, *)
struct LinkMasterCardResponse {
    /// Unique Tangem card ID number
    let cardId: String
    let state: Card.BackupStatus
}

@available(iOS 13.0, *)
final class LinkMasterCardCommand: Command {
    var requiresPasscode: Bool { return true }
    
    private let backupSession: BackupSession
    
    init(backupSession: BackupSession) {
        self.backupSession = backupSession
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if !card.wallets.isEmpty || !card.settings.isBackupAllowed {
            return .backupCannotBeCreated
        }
        
        if backupSession.attestSignature == nil {
            return .backupMasterCardRequired
        }
        
        if !backupSession.slaves.keys.contains(card.cardId) {
            return .backupSlaveCardRequired
        }
        
        if backupSession.slaves.count > 2 {
            return .backupToMuchSlaveCards
        }
        
        return nil
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.pin, value: environment.accessCode.value)
            .append(.pin2, value: environment.passcode.value)
            .append(.backupMasterKey, value: backupSession.master.backupKey)
            .append(.certificate, value: backupSession.master.certificate)
            .append(.backupAttestSignature, value: backupSession.attestSignature)
            .append(.newPin, value: backupSession.newPIN)
            .append(.newPin2, value: backupSession.newPIN2)
            .append(.settingsMask, value: environment.card?.settings.mask)
        
        for (index, card) in backupSession.slaves.enumerated() {
            let builder = try TlvBuilder()
                .append(.fileIndex, value: index)
                .append(.backupSlaveKey, value: card.value.backupKey)
            
            try tlvBuilder.append(.backupCardLink, value: builder.serialize())
        }
        
        return CommandApdu(.backupLinkMasterCard, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> LinkMasterCardResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
      
        let decoder = TlvDecoder(tlv: tlv)

       return LinkMasterCardResponse(cardId: try decoder.decode(.cardId),
                                     state: try decoder.decode(.backupStatus))
    }
}
