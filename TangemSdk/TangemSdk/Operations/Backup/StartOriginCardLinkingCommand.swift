//
//  StartOriginCardLinkingCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public final class StartOriginCardLinkingCommand: Command {
    var requiresPasscode: Bool { return false }
    
    public init() {}
    
    deinit {
        Log.debug("StartOriginCardLinkingCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .backupAvailable {
            return .notSupportedFirmwareVersion
        }
        
        if !card.settings.isBackupAllowed {
            return .backupCannotBeCreated
        }
        
        if card.wallets.isEmpty {
            return .backupCannotBeCreatedEmptyWallets
        }
        
        return nil
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.cardId, value: environment.card?.cardId)
        
        return CommandApdu(.startOriginCardLinking, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> OriginCard {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        guard let cardPublicKey = environment.card?.cardPublicKey else {
            throw TangemSdkError.unknownError
        }
        
        let card = OriginCard(cardId: try decoder.decode(.cardId),
                              cardPublicKey: cardPublicKey,
                              linkingKey: try decoder.decode(.originCardLinkingKey))
        
        return card
    }
}
