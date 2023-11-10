//
//  PublicKeyPreflightReadFilter.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
struct PublicKeyPreflightReadFilter: PreflightReadFilter {
    private let expectedPublicKeyId: Data

    init(publicKeyId: Data) {
        expectedPublicKeyId = publicKeyId
    }

    func onCardRead(_ card: Card, environment: SessionEnvironment) throws {}

    func onFullCardRead(_ card: Card, environment: SessionEnvironment) throws {
        guard let firstPublicKey = card.wallets.first?.publicKey else {
            return
        }

        let publicKeyId = PublicKeyId(walletPublicKey: firstPublicKey)
        if publicKeyId.value != expectedPublicKeyId {
            throw TangemSdkError.walletNotFound
        }
    }
}
