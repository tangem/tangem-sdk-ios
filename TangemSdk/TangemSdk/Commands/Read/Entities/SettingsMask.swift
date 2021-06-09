//
//  SettingsMask.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Stores and maps Tangem card settings.
public struct SettingsMask: OptionSet, Codable, StringArrayConvertible, JSONStringConvertible {
	public let rawValue: Int
	
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
    
	public static let useActivation = SettingsMask(rawValue: 0x0002)
	public static let useBlock = SettingsMask(rawValue: 0x0008)
	public static let allowSetPIN1 = SettingsMask(rawValue: 0x0010)
	public static let allowSetPIN2 = SettingsMask(rawValue: 0x0020)
	public static let useCvc = SettingsMask(rawValue: 0x0040)
	public static let prohibitDefaultPIN1 = SettingsMask(rawValue: 0x0080)
	public static let useOneCommandAtTime = SettingsMask(rawValue: 0x0100)
	public static let useNDEF = SettingsMask(rawValue: 0x0200)
	public static let useDynamicNDEF = SettingsMask(rawValue: 0x0400)
	public static let smartSecurityDelay = SettingsMask(rawValue: 0x0800)
	public static let allowUnencrypted = SettingsMask(rawValue: 0x1000)
	public static let allowFastEncryption = SettingsMask(rawValue: 0x2000)
	public static let protectIssuerDataAgainstReplay = SettingsMask(rawValue: 0x4000)
	public static let allowSelectBlockchain = SettingsMask(rawValue: 0x8000)
	public static let disablePrecomputedNDEF = SettingsMask(rawValue: 0x00010000)
	public static let skipSecurityDelayIfValidatedByIssuer = SettingsMask(rawValue: 0x00020000)
	public static let skipCheckPIN2CVCIfValidatedByIssuer = SettingsMask(rawValue: 0x00040000)
	public static let skipSecurityDelayIfValidatedByLinkedTerminal = SettingsMask(rawValue: 0x00080000)
	public static let restrictOverwriteIssuerExtraData = SettingsMask(rawValue: 0x00100000)
	public static let disableIssuerData = SettingsMask(rawValue: 0x01000000)
	public static let disableUserData = SettingsMask(rawValue: 0x02000000)
	public static let disableFiles = SettingsMask(rawValue: 0x04000000)
	
    static let isReusable = SettingsMask(rawValue: 0x0001)
    static let prohibitPurgeWallet = SettingsMask(rawValue: 0x0004)
    
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(toStringArray())
	}
    
	public init(from decoder: Decoder) throws {
		let values = try decoder.singleValueContainer()
		let stringValues = try values.decode([String].self)
		var mask = SettingsMask()
		
		if stringValues.contains("UseActivation") {
			mask.update(with: SettingsMask.useActivation)
		}
		if stringValues.contains("UseBlock") {
			mask.update(with: SettingsMask.useBlock)
		}
		if stringValues.contains("AllowSetPIN1") {
			mask.update(with: SettingsMask.allowSetPIN1)
		}
		if stringValues.contains("AllowSetPIN2") {
			mask.update(with: SettingsMask.allowSetPIN2)
		}
		if stringValues.contains("UseCvc") {
			mask.update(with: SettingsMask.useCvc)
		}
		if stringValues.contains("ProhibitDefaultPIN1") {
			mask.update(with: SettingsMask.prohibitDefaultPIN1)
		}
		if stringValues.contains("UseOneCommandAtTime") {
			mask.update(with: SettingsMask.useOneCommandAtTime)
		}
		if stringValues.contains("UseNDEF") {
			mask.update(with: SettingsMask.useNDEF)
		}
		if stringValues.contains("UseDynamicNDEF") {
			mask.update(with: SettingsMask.useDynamicNDEF)
		}
		if stringValues.contains("SmartSecurityDelay") {
			mask.update(with: SettingsMask.smartSecurityDelay)
		}
		if stringValues.contains("AllowUnencrypted") {
			mask.update(with: SettingsMask.allowUnencrypted)
		}
		if stringValues.contains("AllowFastEncryption") {
			mask.update(with: SettingsMask.allowFastEncryption)
		}
		if stringValues.contains("ProtectIssuerDataAgainstReplay") {
			mask.update(with: SettingsMask.protectIssuerDataAgainstReplay)
		}
		if stringValues.contains("AllowSelectBlockchain") {
			mask.update(with: SettingsMask.allowSelectBlockchain)
		}
		if stringValues.contains("DisablePrecomputedNDEF") {
			mask.update(with: SettingsMask.disablePrecomputedNDEF)
		}
		if stringValues.contains("SkipSecurityDelayIfValidatedByIssuer") {
			mask.update(with: SettingsMask.skipSecurityDelayIfValidatedByIssuer)
		}
		if stringValues.contains("SkipCheckPIN2CVCIfValidatedByIssuer") {
			mask.update(with: SettingsMask.skipCheckPIN2CVCIfValidatedByIssuer)
		}
		if stringValues.contains("SkipSecurityDelayIfValidatedByLinkedTerminal") {
			mask.update(with: SettingsMask.skipSecurityDelayIfValidatedByLinkedTerminal)
		}
		if stringValues.contains("RestrictOverwriteIssuerExtraData") {
			mask.update(with: SettingsMask.restrictOverwriteIssuerExtraData)
		}
		if stringValues.contains("DisableIssuerData") {
			mask.update(with: SettingsMask.disableIssuerData)
		}
		if stringValues.contains("DisableUserData") {
			mask.update(with: SettingsMask.disableUserData)
		}
		if stringValues.contains("DisableFiles") {
			mask.update(with: SettingsMask.disableFiles)
		}
		
		self = mask
	}
	
    func toStringArray() -> [String] {
        var values = [String]()
        if contains(SettingsMask.useActivation) {
            values.append("UseActivation")
        }
        if contains(SettingsMask.useBlock) {
            values.append("UseBlock")
        }
        if contains(SettingsMask.allowSetPIN1) {
            values.append("AllowSetPIN1")
        }
        if contains(SettingsMask.allowSetPIN2) {
            values.append("AllowSetPIN2")
        }
        if contains(SettingsMask.useCvc) {
            values.append("UseCvc")
        }
        if contains(SettingsMask.prohibitDefaultPIN1) {
            values.append("ProhibitDefaultPIN1")
        }
        if contains(SettingsMask.useOneCommandAtTime) {
            values.append("UseOneCommandAtTime")
        }
        if contains(SettingsMask.useNDEF) {
            values.append("UseNDEF")
        }
        if contains(SettingsMask.useDynamicNDEF) {
            values.append("UseDynamicNDEF")
        }
        if contains(SettingsMask.smartSecurityDelay) {
            values.append("SmartSecurityDelay")
        }
        if contains(SettingsMask.allowUnencrypted) {
            values.append("AllowUnencrypted")
        }
        if contains(SettingsMask.allowFastEncryption) {
            values.append("AllowFastEncryption")
        }
        if contains(SettingsMask.protectIssuerDataAgainstReplay) {
            values.append("ProtectIssuerDataAgainstReplay")
        }
        if contains(SettingsMask.allowSelectBlockchain) {
            values.append("AllowSelectBlockchain")
        }
        if contains(SettingsMask.disablePrecomputedNDEF) {
            values.append("DisablePrecomputedNDEF")
        }
        if contains(SettingsMask.skipSecurityDelayIfValidatedByIssuer) {
            values.append("SkipSecurityDelayIfValidatedByIssuer")
        }
        if contains(SettingsMask.skipCheckPIN2CVCIfValidatedByIssuer) {
            values.append("SkipCheckPIN2CVCIfValidatedByIssuer")
        }
        if contains(SettingsMask.skipSecurityDelayIfValidatedByLinkedTerminal) {
            values.append("SkipSecurityDelayIfValidatedByLinkedTerminal")
        }
        if contains(SettingsMask.restrictOverwriteIssuerExtraData) {
            values.append("RestrictOverwriteIssuerExtraData")
        }
        if contains(SettingsMask.disableIssuerData) {
            values.append("DisableIssuerData")
        }
        if contains(SettingsMask.disableUserData) {
            values.append("DisableUserData")
        }
        if contains(SettingsMask.disableFiles) {
            values.append("DisableFiles")
        }
        return values
    }
}

extension SettingsMask: LogStringConvertible {}

class SettingsMaskBuilder {
	private var settingsMaskValue = 0
	
	func add(_ settings: SettingsMask) {
		settingsMaskValue |= settings.rawValue
	}
	
	func build() -> SettingsMask {
		return SettingsMask(rawValue: settingsMaskValue)
	}
}

extension SettingsMask {
    func toWalletSettingsMask() -> WalletSettingsMask {
        return WalletSettingsMask(rawValue: rawValue)
    }
}
