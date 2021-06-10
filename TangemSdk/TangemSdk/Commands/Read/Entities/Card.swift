//
//  Card.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

///Response for `ReadCommand`. Contains detailed card information.
public struct Card: Codable, JSONStringConvertible {
	/// Unique Tangem card ID number.
	public let cardId: String
    /// Tangem internal manufacturing batch ID.
    public let batchId: String
	/// Public key that is used to authenticate the card against manufacturer’s database.
	/// It is generated one time during card manufacturing.
	public let cardPublicKey: Data
    /// Version of Tangem Card Operation System.
    public let firmwareVersion: FirmwareVersion
    /// Information about manufacturer
    public let manufacturer: Manufacturer
    /// Issuer info
    public let issuer: Issuer
    /// Card settings
    public let settings: Settings
    /// When this value is true, it means that the application is linked to the card,
    /// and COS will not enforce security delay if `SignCommand` will be called
    /// with `TlvTag.TerminalTransactionSignature` parameter containing a correct signature of raw data
    /// to be signed made with `TlvTag.TerminalPublicKey`.
    public let terminalIsLinked: Bool
    /// Available only for cards with COS v.4.0 and higher.
    public let pin2IsDefault: Bool?
    /// All ellipctic curves, supported by this card
    public let supportedCurves: [EllipticCurve]
    /// All wallets of the card
    internal(set) public var wallets: [Wallet] = []
    /// True value indicates that the card experiences some hardware problems.
    /// User should withdraw the value to other blockchain wallet as soon as possible.
//    var cardHealth: Bool {
//        if let health = health, health != 0 {
//            return true
//        }
//        return false
//    }
    /// Any non-zero value indicates that the card experiences some hardware problems.
    /// User should withdraw the value to other blockchain wallet as soon as possible.
    /// Non-zero Health tag will also appear in responses of all other commands.
    let health: Int? //todo refactor
    /// Remaining number of `SignCommand` operations before the wallet will stop signing transactions.
    /// - Note: This counter were deprecated for cards with COS 4.0 and higher
    let remainingSignatures: Int?
}

public extension Card {
    struct Manufacturer: Codable {
        /// Name of Tangem card manufacturer.
        public let name: String
        /// Timestamp of manufacturing.
        public let manufactureDate: Date
        /// Signature of CardId with manufacturer’s private key. COS 1.21+
        public let signature: Data?
    }
    
    struct Issuer: Codable {
        /// Name of the issuer.
        public let name: String
        /// Public key that is used by the card issuer to sign IssuerData field.
        public let publicKey: Data
    }
    
    struct Settings: Codable {
        /// Delay in centiseconds before COS executes commands protected by PIN2. This is a security delay value
        public let securityDelay: Int //todo: convert to ms
        /// Card settings defined by personalization (bit mask: 0 – Enabled, 1 – Disabled).
        public let mask: SettingsMask
        /// Maximum number of wallets that can be created for this card
        public let maxWalletsCount: Int
        /// Card's signing methods according personalization. We need it to make Wallet for pre-v4 COS
        let _v3_signingMethods: SigningMethod?
    }
    
    /// Describing wallets created on card
    struct Wallet: Codable, JSONStringConvertible {
        /// Index of the wallet in the card storage
        public let index: Int
        /// Public key of the blockchain wallet.
        public var publicKey: Data
        /// Explicit text name of the elliptic curve used for all wallet key operations.
        /// Supported curves: ‘secp256k1’ and ‘ed25519’.
        public var curve: EllipticCurve
        /// Settings of the wallet
        public var settingsMask: WalletSettingsMask
        /// Defines what data should be submitted to SIGN command.
        public let signingMethods: SigningMethod
        /// Total number of signed  hashes returned by the wallet since its creation
        /// COS 1.16+
        public var totalSignedHashes: Int?
        /// Remaining number of `SignCommand` operations before the wallet will stop signing transactions.
        /// - Note: This counter were deprecated for cards with COS 4.0 and higher
        public var remainingSignatures: Int?
    }
}
