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
    /// Index of wallet in card storage
    /// Use this index to create `WalletIndex` for interaction with wallet on card
    public let index: Int //todo: remove
    /// Current status of wallet
    /// Statuses: empty = 1, loaded = 2, purged = 3
    public var status: WalletStatus //todo: DV
    /// Explicit text name of the elliptic curve used for all wallet key operations.
    /// Supported curves: ‘secp256k1’ and ‘ed25519’.
    public var curve: EllipticCurve?
    public var settingsMask: SettingsMask? //todo: separate to another one
    /// Public key of the blockchain wallet.
    public var publicKey: Data? //todo: optional or not
    /// Total number of signed single hashes returned by the card in
    /// `SignCommand` responses since card personalization.
    /// Sums up array elements within all `SignCommand`.
    public var signedHashes: Int? //todo:rename totalSignedHashes
    /// Remaining number of `SignCommand` operations before the wallet will stop signing transactions.
    /// - Note: This counter were deprecated for cards with COS 4.0 and higher
    public var remainingSignatures: Int?
    
    public var intIndex: WalletIndex {
        .index(index)
    }
    
    public var pubkeyIndex: WalletIndex? {
        publicKey == nil ? nil : .publicKey(publicKey!)
    }
    
    init(index: Int, status: WalletStatus, curve: EllipticCurve? = nil, settingsMask: SettingsMask? = nil, publicKey: Data? = nil, signedHashes: Int? = nil, remainingSignatures: Int? = nil) {
        self.index = index
        self.status = status
        self.curve = curve
        self.settingsMask = settingsMask
        self.publicKey = publicKey
        self.signedHashes = signedHashes
        self.remainingSignatures = remainingSignatures
    }
    
    init(from response: CreateWalletResponse, with curve: EllipticCurve, settings: SettingsMask?) {
        self.index = response.walletIndex
        self.status = WalletStatus(from: response.status)
        self.curve = curve
        self.settingsMask = settings
        self.publicKey = response.walletPublicKey
        self.signedHashes = 0
        remainingSignatures = nil
    }
}
