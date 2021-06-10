//
//  WalletSettingsMask.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Stores and maps Wallet settings
/// - Note: Available only for cards with COS v.4.0
public struct WalletSettingsMask: Codable, OptionSet, StringArrayConvertible, JSONStringConvertible {
	public var rawValue: Int
	
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	public static let isProhibitPurge = WalletSettingsMask(rawValue: 0x0004)
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(toStringArray())
	}
	
	public init(from decoder: Decoder) throws {
		let values = try decoder.singleValueContainer()
		let stringValues = try values.decode([String].self)
		var mask = WalletSettingsMask()
		if stringValues.contains("isProhibitPurge") {
			mask.update(with: .isProhibitPurge)
		}
		self = mask
	}
    
    func toStringArray() -> [String] {
        var values = [String]()
        
        if contains(.isProhibitPurge) {
            values.append("isProhibitPurge")
        }
        return values
    }
}

extension WalletSettingsMask: LogStringConvertible {}

class WalletSettingsMaskBuilder {
	private var settingsMaskValue = 0
	
	func add(_ settings: WalletSettingsMask) {
		settingsMaskValue |= settings.rawValue
	}
	
	func build() -> WalletSettingsMask {
		WalletSettingsMask(rawValue: settingsMaskValue)
	}
}
