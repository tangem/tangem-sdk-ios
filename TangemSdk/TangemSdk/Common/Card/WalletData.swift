//
//  WalletData.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 15.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public struct WalletData: Equatable, Hashable {
    /// Name of the blockchain.
    public let blockchain: String
    /// Token of the specified blockchain.
    public let token: Token?
}

public struct Token: Equatable, Hashable {
    /// Display name of the token.
    public let name: String
    /// Token symbol
    public let symbol: String
    /// Smart contract address.
    public let contractAddress: String
    /// Number of decimals in token value.
    public let decimals: Int
}
