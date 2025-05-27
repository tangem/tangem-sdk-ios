//
//  CommonOnlineAttestationService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24/03/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

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

    func attestCard() -> AnyPublisher<OnlineAttestationResponse, Error> {
        getAttestationData()
            .tryMap { response in
                if try verifier.verify(response: response) {
                    cache.append(cardPublicKey: cardPublicKey, response: response)
                    return response
                }

                throw TangemSdkError.cardVerificationFailed
            }
            .eraseToAnyPublisher()
    }

    private func getAttestationData() -> AnyPublisher<OnlineAttestationResponse, NetworkServiceError> {
        if let cached = cache.response(for: cardPublicKey) {
            return Just(cached)
                .setFailureType(to: NetworkServiceError.self)
                .eraseToAnyPublisher()
        } else {
            return requestAttestationData()
        }
    }

    private func requestAttestationData() -> AnyPublisher<OnlineAttestationResponse, NetworkServiceError> {
        networkService
            .requestPublisher(TangemEndpoint.cardData(cardId: cardId, cardPublicKey: cardPublicKey))
            .eraseToAnyPublisher()
    }
}
