//
//  CommonOnlineAttestationService.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CommonOnlineAttestationService: OnlineAttestationService {
    private let cardId: String
    private let cardPublicKey: Data
    private let verifier: OnlineAttestationVerifier
    private let networkService: NetworkService

    private let cache = OnlineAttestationCache()

    init(
        cardId: String,
        cardPublicKey: Data,
        verifier: OnlineAttestationVerifier,
        networkService: NetworkService
    ) {
        self.cardId = cardId
        self.cardPublicKey = cardPublicKey
        self.verifier = verifier
        self.networkService = networkService
    }

    func attestCard() async throws -> OnlineAttestationResponse {
        let response = try await getAttestationData()

        if try verifier.verify(response: response) {
            cache.append(cardPublicKey: cardPublicKey, response: response)
            return response
        }

        throw TangemSdkError.cardVerificationFailed
    }

    private func getAttestationData() async throws(NetworkServiceError) -> OnlineAttestationResponse {
        if let cached = cache.response(for: cardPublicKey) {
            return cached
        } else {
            return try await requestAttestationData()
        }
    }

    private func requestAttestationData() async throws(NetworkServiceError) -> OnlineAttestationResponse {
        try await networkService.request(TangemEndpoint.cardData(cardId: cardId, cardPublicKey: cardPublicKey))
    }
}
