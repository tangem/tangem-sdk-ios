//
//  SignResetPinToken.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
final class SignResetPinTokenCommand: Command {
    var requiresPasscode: Bool { return false }
    var preflightReadMode: PreflightReadMode { .readCardOnly }
    
    private let resetPinCard: ResetPinCard
    
    init(resetPinCard: ResetPinCard) {
        self.resetPinCard = resetPinCard
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        guard let backupStatus = card.backupStatus,
              backupStatus.isActive else {
            return TangemSdkError.invalidState
        }
        
        return nil
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.interactionMode, value: AuthorizeMode.tokenSign)
            .append(.challenge, value: resetPinCard.token)
            .append(.originCardLinkingKey, value: resetPinCard.backupKey)
            .append(.backupAttestSignature, value: resetPinCard.attestSignature)
        
        return CommandApdu(.authorize, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ConfirmationCard {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        let card = ConfirmationCard(cardId: try decoder.decode(.cardId),
                                    backupKey: try decoder.decode(.backupCardLinkingKey),
                                    salt: try decoder.decode(.salt),
                                    authorizeSignature: try decoder.decode(.backupAttestSignature))
        
        return card
    }
}
