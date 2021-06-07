//
//  Card.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

///Response for `ReadCommand`. Contains detailed card information.
public struct Card: JSONStringConvertible {
	/// Unique Tangem card ID number.
	public let cardId: String? //todo: not optional?
	/// Name of Tangem card manufacturer.
	public let manufacturerName: String?
	/// Public key that is used to authenticate the card against manufacturer’s database.
	/// It is generated one time during card manufacturing.
	public let cardPublicKey: Data?
	/// Card settings defined by personalization (bit mask: 0 – Enabled, 1 – Disabled).
	public let settingsMask: SettingsMask?
	/// Public key that is used by the card issuer to sign IssuerData field.
	public let issuerPublicKey: Data?
	/// Defines what data should be submitted to SIGN command.
	public let signingMethods: SigningMethod? //todo: rafactor to Settings
	/// Delay in centiseconds before COS executes commands protected by PIN2. This is a security delay value
	public let pauseBeforePin2: Int? //todo: rename to securityDelay
	/// Any non-zero value indicates that the card experiences some hardware problems.
	/// User should withdraw the value to other blockchain wallet as soon as possible.
	/// Non-zero Health tag will also appear in responses of all other commands.
	public let health: Int?
	/// When this value is true, it means that the application is linked to the card,
	/// and COS will not enforce security delay if `SignCommand` will be called
	/// with `TlvTag.TerminalTransactionSignature` parameter containing a correct signature of raw data
	/// to be signed made with `TlvTag.TerminalPublicKey`.
	public let terminalIsLinked: Bool
	/// Detailed information about card contents. Format is defined by the card issuer.
	/// Cards complaint with Tangem Wallet application should have TLV format.
	public let cardData: CardData?
	
    /// Version of Tangem COS.
    public var firmwareVersion: FirmwareVersion? { //todo refactor
        if let version = fwVersion {
            return FirmwareVersion(version: version)
        } else {
            return nil
        }
    }
    
	/// Available only for cards with COS v.4.0 and higher.
    internal(set) public var pin2IsDefault: Bool? = nil
    
	/// Maximum number of wallets that can be created for this card
    internal(set) public var walletsCount: Int?//todo: rename
    
    internal(set) public var wallets: [CardWallet] = []
    
    internal let fwVersion: String?
    
    internal let defaultCurve: EllipticCurve?
    /// Remaining number of `SignCommand` operations before the wallet will stop signing transactions.
    /// - Note: This counter were deprecated for cards with COS 4.0 and higher
    internal let remainingSignatures: Int?
}

public extension Card {
	var firmwareVersionValue: Double? {
		firmwareVersion?.versionDouble
	}
	
	var isLinkedTerminalSupported: Bool {
		return settingsMask?.contains(SettingsMask.skipSecurityDelayIfValidatedByLinkedTerminal) ?? false
	}
	
	var cardType: FirmwareType {
		return firmwareVersion?.type ?? .special
	}
}
