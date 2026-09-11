//
//  ExtendedKeySerializer.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum ExtendedKeySerializer {
    enum Version {
        case `public`
        case `private`

        func getPrefix(for networkType: NetworkType) -> UInt32 {
            switch (self, networkType) {
            case (.public, .mainnet):
                return 0x0488b21e
            case (.public, .testnet):
                return 0x043587cf
            case (.private, .mainnet):
                return 0x0488ADE4
            case (.private, .testnet):
                return 0x04358394
            }
        }
    }

    enum Constants {
        static let dataLength: Int = 78
    }
}
