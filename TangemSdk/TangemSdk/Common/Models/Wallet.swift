//
//  Wallet.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 10.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public extension Card {
    /// Describing wallets created on card
    struct Wallet: Codable, JSONStringConvertible {
        /// Wallet's public key.
        public let publicKey: Data
        /// Elliptic curve used for all wallet key operations.
        public let curve: EllipticCurve
        /// Wallet's settings
        public let settings: Settings
        /// Total number of signed hashes returned by the wallet since its creation
        /// COS 1.16+
        public var totalSignedHashes: Int?
        /// Remaining number of `Sign` operations before the wallet will stop signing any data.
        /// - Note: This counter were deprecated for cards with COS 4.0 and higher
        public var remainingSignatures: Int?
        /// Index of the wallet in the card storage
        internal let index: Int
    }
}

public extension Card.Wallet {
    struct Settings: Codable {
        /// Settings of the wallet
        public let mask: Mask
        /// Defines what data should be submitted to SIGN command.
        public let signingMethods: SigningMethod
        /// Total number of signed hashes returned by the wallet since its creation
    }
}

public extension Card.Wallet.Settings {
    /// Stores and maps Wallet settings
    /// - Note: Available only for cards with COS v.4.0
    struct Mask: OptionSet, JSONStringConvertible, OptionSetCustomStringConvertible {
        public static let isProhibitPurge = Mask(rawValue: 0x0004)
        
        public var rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
}

extension Card.Wallet {
    /// Status of the wallet
    enum Status: Int, StatusType {
        /// Wallet not created
        case empty = 1
        /// Wallet created and can be used for signing
        case loaded = 2
        /// Wallet was purged and can't be recreated or used for signing
        case purged = 3
    }
}

extension Card.Wallet.Settings.Mask: OptionSetCodable {
    public enum OptionKeys: String, OptionKey {
        case isProhibitPurge
        
        public var value: Card.Wallet.Settings.Mask {
            switch self {
            case .isProhibitPurge:
                return .isProhibitPurge
            }
        }
    }
}

class WalletSettingsMaskBuilder {
    private var settingsMaskValue = 0
    
    func add(_ settings: Card.Wallet.Settings.Mask) {
        settingsMaskValue |= settings.rawValue
    }
    
    func build() -> Card.Wallet.Settings.Mask {
        Card.Wallet.Settings.Mask(rawValue: settingsMaskValue)
    }
}
