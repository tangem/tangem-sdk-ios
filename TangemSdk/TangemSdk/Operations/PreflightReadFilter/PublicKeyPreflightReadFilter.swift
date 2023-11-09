//
//  PublicKeyPreflightReadFilter.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public struct PublicKeyPreflightReadFilter: PreflightReadFilter {
    private let expectedPublicKeyId: Data

    public init(publicKeyId: Data) {
        expectedPublicKeyId = publicKeyId
    }

    public func onCardRead(_ card: Card, environment: SessionEnvironment) throws {}

    public func onFullCardRead(_ card: Card, environment: SessionEnvironment) throws {
        guard environment.config.handleErrors,
              let firstPublicKey = card.wallets.first?.publicKey else {
            return
        }

        let publicKeyId = PublicKeyId(walletPublicKey: firstPublicKey)
        if publicKeyId.value != expectedPublicKeyId {
            throw TangemSdkError.walletNotFound
        }
    }
}
