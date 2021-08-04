//
//  Bip44PathBuilder.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public struct Bip44PathBuilder {
    public let purpose: UInt32 = 44
    public let coinType: CoinType
    public let account: UInt32
    public let change: Bip44Chain
    public let addressIndex: UInt32
    
    public init(coinType: CoinType, account: UInt32, change: Bip44Chain, addressIndex: UInt32) {
        self.coinType = coinType
        self.account = account
        self.change = change
        self.addressIndex = addressIndex
    }
    
    /// Build path
    /// - Parameter notHardenedOnly: Because we don't have access to the private key,
    /// we can use non-hardened derivation only without tapping the Tangem card.
    /// - Returns: Path according Bip32
    public func buildPath(notHardenedOnly: Bool = true) -> DerivationPath {
        let nodes: [DerivationNode] = [notHardenedOnly ? .notHardened(purpose) : .hardened(purpose),
                                       notHardenedOnly ? .notHardened(coinType.index) : .hardened(coinType.index),
                                       notHardenedOnly ? .notHardened(account) : .hardened(account),
                                       .notHardened(change.index),
                                       .notHardened(addressIndex)]
        return DerivationPath(path: nodes)
    }
}

public enum Bip44Chain {
    case external
    case `internal`
    
    public var index: UInt32 {
        switch self {
        case .external:
            return 0
        case .internal:
            return 1
        }
    }
}

public enum CoinType {
    case bitcoin
    case testnet
    case litecoin
    case doge
    case stellar
    case ethereum
    case rsk
    case bitcoinCash
    case binance
    case cardano
    case xrp
    case tezos
    case polygon
    case other(index: UInt32)
    
    public var index: UInt32 {
        switch self {
        case .bitcoin: return 0
        case .testnet: return 1
        case .litecoin: return 2
        case .doge: return 3
        case .ethereum: return 60
        case .stellar: return 148
        case .rsk: return 137
        case .bitcoinCash: return 145
        case .binance: return 714
        case .cardano: return 1815
        case .xrp: return 144
        case .tezos: return 1729
        case .polygon: return 966
        case .other(let index):
            return index
        }
    }
}
