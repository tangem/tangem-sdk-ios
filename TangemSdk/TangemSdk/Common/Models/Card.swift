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
    /// Information about issuer
    public let issuer: Issuer
    /// Card setting, that were set during the personalization process
    public let settings: Settings
    /// When this value is `current`, it means that the application is linked to the card,
    /// and COS will not enforce security delay if `SignCommand` will be called
    /// with `TlvTag.TerminalTransactionSignature` parameter containing a correct signature of raw data
    /// to be signed made with `TlvTag.TerminalPublicKey`.
    public let linkedTerminalStatus: LinkedTerminalStatus
    /// PIN2 (aka Passcode) is default.
    /// Available only for cards with COS v.4.0 and higher.
    public let isPin2Default: Bool?
    /// Array of ellipctic curves, supported by this card. Only wallets with these curves can be created.
    public let supportedCurves: [EllipticCurve]
    /// Wallets, created on the card, that can be used for signature
    internal(set) public var wallets: [Wallet] = []
    /// Any non-zero value indicates that the card experiences some hardware problems.
    /// User should withdraw the value to other blockchain wallet as soon as possible.
    /// Non-zero Health tag will also appear in responses of all other commands.
    let health: Int? //todo refactor
    /// Remaining number of `SignCommand` operations before the wallet will stop signing transactions.
    /// - Note: This counter were deprecated for cards with COS 4.0 and higher
    let remainingSignatures: Int?
    
    internal(set) public var attestation: Attestation = .skipped
}

public extension Card {
    struct Manufacturer: Codable {
        /// Card manufacturer name.
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
        /// Delay before executing a command that affects any sensitive data or wallets on the card.
        public let securityDelay: Int //todo: convert to ms
        /// Card settings defined by personalization (bit mask: 0 – Enabled, 1 – Disabled).
        public let mask: Mask
        /// Maximum number of wallets that can be created for this card
        public let maxWalletsCount: Int
        /// Card's default signing methods according personalization.
        let defaultSigningMethods: SigningMethod?
        /// Card's default signing methods according personalization.
        let defaultCurve: EllipticCurve?
    }
}

extension Card {
    /// Status of the card and its wallet.
    enum Status: Int, Codable, StatusType {
        case notPersonalized = 0
        case empty = 1
        case loaded = 2
        case purged = 3
    }
}

