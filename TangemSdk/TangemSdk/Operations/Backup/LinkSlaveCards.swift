//
//  LinkSlaveCards.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

// Response from the Tangem card after `LinkSlaveCardsCommand`.
@available(iOS 13.0, *)
struct LinkSlaveCardsResponse {
    /// Unique Tangem card ID number
    let cardId: String
    let attestSignature: Data
}

@available(iOS 13.0, *)
final class LinkSlaveCardsCommand: Command {
    var requiresPasscode: Bool { return true }
    //todo: slaves
    
    private let backupSession: BackupSession
    
    init(backupSession: BackupSession) {
        self.backupSession = backupSession
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.wallets.isEmpty || !card.settings.isBackupAllowed {
            return .backupCannotBeCreated
        }
        //todo: check by cardId
        if backupSession.master.cardKey != card.cardPublicKey {
            return .backupMasterCardRequired
        }
        //todo: move to service
        if backupSession.slaves.isEmpty {
            return .backupSlaveCardRequired
        }
        //todo: move to service
        if backupSession.slaves.count > 2 {
            return .backupToMuchSlaveCards
        }
        
        return nil
    }
    
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.pin2, value: environment.passcode.value)
            .append(.backupCount, value: backupSession.slaves.count)
            .append(.newPin, value: backupSession.newPIN) //todo: TBD
            .append(.newPin2, value: backupSession.newPIN2)
        
        for (index, card) in backupSession.slaves.enumerated() {
            let builder = try TlvBuilder()
                .append(.fileIndex, value: index)
                .append(.backupSlaveKey, value: card.value.backupKey)
                .append(.certificate, value: card.value.certificate)
                .append(.cardSignature, value: card.value.attestSignature)
            
            try tlvBuilder.append(.backupCardLink, value: builder.serialize())
        }
        
        return CommandApdu(.backupLinkSlaveCards, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> LinkSlaveCardsResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        let prefix = "BACKUP".data(using: .utf8)!
        var dataAttest = prefix + backupSession.slaves.count.byte
        dataAttest += backupSession.master.backupKey
        dataAttest += backupSession.slaves.map { $0.value.backupKey }.joined()
        dataAttest += backupSession.newPIN!
        dataAttest += backupSession.newPIN2!
        dataAttest += environment.card!.settings.mask.rawValue.bytes4
        
        let attestSignature: Data = try decoder.decode(.backupAttestSignature)
        
        let verified = try CryptoUtils.verify(curve: .secp256k1, publicKey: backupSession.master.cardKey,
                                              message: dataAttest,
                                              signature: attestSignature)
        
        if !verified {
            throw TangemSdkError.backupInvalidSignature
        }
        
        return LinkSlaveCardsResponse(cardId: try decoder.decode(.cardId),
                                      attestSignature: attestSignature)
    }
}
