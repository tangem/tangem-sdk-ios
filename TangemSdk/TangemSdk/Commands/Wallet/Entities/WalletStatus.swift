//
//  WalletStatus.swift
//  TangemSdk
//
//  Created by Andrew Son on 24/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Status of the wallet
enum WalletStatus: Int, StatusType {
    /// Wallet not created
    case empty = 1
    /// Wallet created and can be used for signing
    case loaded = 2
    /// Wallet was purged and can't be recreated or used for signing
    case purged = 3
}
