//
//  OnlineAttestationServiceFactory.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24/03/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct OnlineAttestationServiceFactory {
    private let newAttestaionService: Bool

    public init(newAttestaionService: Bool) {
        self.newAttestaionService = newAttestaionService
    }

    func makeService(for card: Card) -> OnlineAttestationService {
        return makeService(
            cardId: card.cardId,
            cardPublicKey: card.cardPublicKey,
            issuerPublicKey: card.issuer.publicKey,
            firmwareVersion: card.firmwareVersion
        )
    }

    func makeService(
        cardId: String,
        cardPublicKey: Data,
        issuerPublicKey: Data,
        firmwareVersion: FirmwareVersion
    ) -> OnlineAttestationService {
        if firmwareVersion.type == .sdk {
            return DevOnlineAttestationService(cardPublicKey: cardPublicKey)
        }

        let verifier = OnlineAttestationVerifier(
            cardPublicKey: cardPublicKey,
            issuerPublicKey: issuerPublicKey,
            newAttestaionService: newAttestaionService
        )

        return CommonOnlineAttestationService(
            cardId: cardId,
            cardPublicKey: cardPublicKey,
            verifier: verifier,
            networkService: .init()
        )
    }
}
