//
//  PublicKeyId.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

@available(iOS 13.0, *)
public struct PublicKeyId {
    public private (set) var value: Data

    public init(value: Data) {
        self.value = value
    }

    public init(walletPublicKey: Data) {
        let keyHash = walletPublicKey.getSha256()
        let key = SymmetricKey(data: keyHash)
        let authenticationCode = HMAC<SHA256>.authenticationCode(for: Constants.message, using: key)
        value = Data(authenticationCode)
    }
}

@available(iOS 13.0, *)
private extension PublicKeyId {
    enum Constants {
        static let message = "UserWalletID".data(using: .utf8)!
    }
}
