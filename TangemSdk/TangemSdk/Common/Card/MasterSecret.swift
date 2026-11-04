//
//  MasterSecret.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension Card {
    /// Master secret info, created on the card, that can be used for deterministic entropy (BIP-0085)
    struct MasterSecret: Codable {
        /// Secret's public key.
        public let publicKey: Data?
        /// Optional chain code for BIP32 derivation.
        public let chainCode: Data?
        /// Elliptic curve used for all wallet key operations.
        public let curve: EllipticCurve
        /// Has this key been imported to a card. E.g. from seed phrase
        public let isImported: Bool
        /// Shows whether this wallet has a backup
        public let hasBackup: Bool
        /// Raw status of the wallet
        let status: Card.Wallet.Status
    }
}
