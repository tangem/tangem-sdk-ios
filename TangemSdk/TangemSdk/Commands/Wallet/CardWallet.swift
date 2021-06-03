//
//  CardWallet.swift
//  TangemSdk
//
//  Created by Andrew Son on 16/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Describing wallets created on card
public struct CardWallet: Codable, JSONStringConvertible {
    /// Index of the wallet in the card storage
    public let index: Int
    /// Current status of wallet
    /// Statuses: empty = 1, loaded = 2, purged = 3
    // public var status: WalletStatus //todo: DV
    /// Explicit text name of the elliptic curve used for all wallet key operations.
    /// Supported curves: ‘secp256k1’ and ‘ed25519’.
    public var curve: EllipticCurve
    public var settingsMask: SettingsMask? //todo: separate to another one
    /// Public key of the blockchain wallet.
    public var publicKey: Data
    /// Total number of signed  hashes returned by the wallet since its creation
    /// COS 1.16+
    public var totalSignedHashes: Int?
    /// Remaining number of `SignCommand` operations before the wallet will stop signing transactions.
    /// - Note: This counter were deprecated for cards with COS 4.0 and higher
    public var remainingSignatures: Int?
}
