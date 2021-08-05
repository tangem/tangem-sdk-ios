//
//  BIP44.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public struct BIP44 {
    public let coinType: UInt32
    public let account: UInt32
    public let change: Chain
    public let addressIndex: UInt32
    
    public static let purpose: UInt32 = 44
    
    public init(coinType: UInt32, account: UInt32, change: Chain, addressIndex: UInt32) {
        self.coinType = coinType
        self.account = account
        self.change = change
        self.addressIndex = addressIndex
    }
    
    /// Build path
    /// - Parameter notHardenedOnly: Because we don't have access to the private key,
    /// we can use non-hardened derivation only without tapping the Tangem card.
    /// - Returns: Path according BIP32
    public func buildPath(notHardenedOnly: Bool = true) -> DerivationPath {
        let nodes: [DerivationNode] = [notHardenedOnly ? .notHardened(BIP44.purpose) : .hardened(BIP44.purpose),
                                       notHardenedOnly ? .notHardened(coinType) : .hardened(coinType),
                                       notHardenedOnly ? .notHardened(account) : .hardened(account),
                                       .notHardened(change.index),
                                       .notHardened(addressIndex)]
        return DerivationPath(nodes: nodes)
    }
    
    /// Build path m/44/coinType
    /// - Parameter coinType: UInt32 index of the coin
    /// - Returns: DerivationPath m/44/coinType
    public static func buildPath(for coinType: UInt32) -> DerivationPath {
        let nodes: [DerivationNode] = [.notHardened(BIP44.purpose), .notHardened(coinType)]
        return DerivationPath(nodes: nodes)
    }
}

public extension BIP44 {
    enum Chain {
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
}
