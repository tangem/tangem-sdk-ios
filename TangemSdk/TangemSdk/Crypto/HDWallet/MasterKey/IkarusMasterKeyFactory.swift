//
//  IkarusMasterKeyFactory.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct IkarusMasterKeyFactory: MasterKeyFactory {
    private let entropy: Data
    private let passphrase: String

    init(entropy: Data, passphrase: String) {
        self.entropy = entropy
        self.passphrase = passphrase
    }

    func makePrivateKey() throws -> ExtendedPrivateKey {
      return try SLIP23().makeIkarusMasterKey(entropy: entropy, passphrase: passphrase)
    }
}
