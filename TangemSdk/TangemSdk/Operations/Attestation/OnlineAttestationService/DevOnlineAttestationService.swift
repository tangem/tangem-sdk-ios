//
//  DevOnlineAttestationService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24/03/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

struct DevOnlineAttestationService: OnlineAttestationService {
    private let cardPublicKey: Data

    init(cardPublicKey: Data) {
        self.cardPublicKey = cardPublicKey
    }

    func attestCard() -> AnyPublisher<OnlineAttestationResponse, Error> {
        Result {
             try makeDevResponse(cardPublicKey: cardPublicKey)
        }
        .publisher
        .eraseToAnyPublisher()
    }

    private func makeDevResponse(cardPublicKey: Data) throws -> OnlineAttestationResponse {
        let sdkIssuerSignature = try cardPublicKey.sign(privateKey: Constants.sdkIssuerPrivateKey)
        let manufacturerSignature = Data() // no validation for dev

        return OnlineAttestationResponse(
            manufacturerSignature: manufacturerSignature,
            issuerSignature: sdkIssuerSignature
        )
    }
}

// MARK: - Constants

private extension DevOnlineAttestationService {
    enum Constants {
        static let sdkIssuerPrivateKey = Data(hexString: "11121314151617184771ED81F2BACF57479E4735EB1405083927372D40DA9E92")
    }
}
