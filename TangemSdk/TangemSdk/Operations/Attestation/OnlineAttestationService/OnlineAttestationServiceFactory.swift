//
//  OnlineAttestationServiceFactory.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24/03/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct OnlineAttestationServiceFactory {
    private let networkService: NetworkService
    private let newAttestationService: Bool

    public init(networkService: NetworkService, newAttestationService: Bool) {
        self.networkService = networkService
        self.newAttestationService = newAttestationService
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
            newAttestationService: newAttestationService
        )

        return CommonOnlineAttestationService(
            cardId: cardId,
            cardPublicKey: cardPublicKey,
            verifier: verifier,
            networkService: networkService
        )
    }
}
