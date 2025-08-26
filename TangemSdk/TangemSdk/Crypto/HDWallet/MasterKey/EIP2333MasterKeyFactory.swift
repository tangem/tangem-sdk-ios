//
//  EIP2333MasterKeyFactory.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct EIP2333MasterKeyFactory: MasterKeyFactory {
    private let seed: Data

    init(seed: Data) {
        self.seed = seed
    }

    func makePrivateKey() throws -> ExtendedPrivateKey {
        let keyData = try BLSUtils().generateKey(inputKeyMaterial: seed)
        return ExtendedPrivateKey(privateKey: keyData, chainCode: Data())
    }
}
