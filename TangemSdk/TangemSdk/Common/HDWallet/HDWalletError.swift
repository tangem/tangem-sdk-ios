//
//  HDWalletError.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

enum HDWalletError: Error {
    case hardenedNotSupported
    case derivationFailed
    case wrongPath
}
