//
//  BIP32.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct BIP32 {
    enum Constants {
        static let hardenedOffset: UInt32 = .init(0x80000000)
        static let hardenedSymbol: String = "'"
        static let alternativeHardenedSymbol: String = "’"
        static let masterKeySymbol: String = "m"
        static let separatorSymbol: Character = "/"
    }
}

