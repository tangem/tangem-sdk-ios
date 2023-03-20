//
//  HDWalletError.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

enum HDWalletError: String, Error, LocalizedError {
    case hardenedNotSupported
    case wrongPath
    case wrongIndex
    case invalidSeed
    case invalidHMACKey
    
    var errorDescription: String? {
        return rawValue
    }
}
