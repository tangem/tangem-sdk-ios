//
//  .swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public extension Card.Settings {
    /// Stores and maps Tangem card settings.
    struct Mask: OptionSet, Codable, StringArrayConvertible, JSONStringConvertible, LogStringConvertible {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let useActivation = Mask(rawValue: 0x0002)
        public static let useBlock = Mask(rawValue: 0x0008)
        public static let allowSetPIN1 = Mask(rawValue: 0x0010)
        public static let allowSetPIN2 = Mask(rawValue: 0x0020)
        public static let useCvc = Mask(rawValue: 0x0040)
        public static let prohibitDefaultPIN1 = Mask(rawValue: 0x0080)
        public static let useOneCommandAtTime = Mask(rawValue: 0x0100)
        public static let useNDEF = Mask(rawValue: 0x0200)
        public static let useDynamicNDEF = Mask(rawValue: 0x0400)
        public static let smartSecurityDelay = Mask(rawValue: 0x0800)
        public static let allowUnencrypted = Mask(rawValue: 0x1000)
        public static let allowFastEncryption = Mask(rawValue: 0x2000)
        public static let protectIssuerDataAgainstReplay = Mask(rawValue: 0x4000)
        public static let allowSelectBlockchain = Mask(rawValue: 0x8000)
        public static let disablePrecomputedNDEF = Mask(rawValue: 0x00010000)
        public static let skipSecurityDelayIfValidatedByIssuer = Mask(rawValue: 0x00020000)
        public static let skipCheckPIN2CVCIfValidatedByIssuer = Mask(rawValue: 0x00040000)
        public static let skipSecurityDelayIfValidatedByLinkedTerminal = Mask(rawValue: 0x00080000)
        public static let restrictOverwriteIssuerExtraData = Mask(rawValue: 0x00100000)
        public static let disableIssuerData = Mask(rawValue: 0x01000000)
        public static let disableUserData = Mask(rawValue: 0x02000000)
        public static let disableFiles = Mask(rawValue: 0x04000000)
        
        static let isReusable = Mask(rawValue: 0x0001)
        static let prohibitPurgeWallet = Mask(rawValue: 0x0004)
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(toStringArray())
        }
        
        public init(from decoder: Decoder) throws {
            let values = try decoder.singleValueContainer()
            let stringValues = try values.decode([String].self)
            var mask = Mask()
            
            if stringValues.contains("UseActivation") {
                mask.update(with: .useActivation)
            }
            if stringValues.contains("UseBlock") {
                mask.update(with: .useBlock)
            }
            if stringValues.contains("AllowSetPIN1") {
                mask.update(with: .allowSetPIN1)
            }
            if stringValues.contains("AllowSetPIN2") {
                mask.update(with: .allowSetPIN2)
            }
            if stringValues.contains("UseCvc") {
                mask.update(with: .useCvc)
            }
            if stringValues.contains("ProhibitDefaultPIN1") {
                mask.update(with: .prohibitDefaultPIN1)
            }
            if stringValues.contains("UseOneCommandAtTime") {
                mask.update(with: .useOneCommandAtTime)
            }
            if stringValues.contains("UseNDEF") {
                mask.update(with: .useNDEF)
            }
            if stringValues.contains("UseDynamicNDEF") {
                mask.update(with: .useDynamicNDEF)
            }
            if stringValues.contains("SmartSecurityDelay") {
                mask.update(with: .smartSecurityDelay)
            }
            if stringValues.contains("AllowUnencrypted") {
                mask.update(with: .allowUnencrypted)
            }
            if stringValues.contains("AllowFastEncryption") {
                mask.update(with: .allowFastEncryption)
            }
            if stringValues.contains("ProtectIssuerDataAgainstReplay") {
                mask.update(with: .protectIssuerDataAgainstReplay)
            }
            if stringValues.contains("AllowSelectBlockchain") {
                mask.update(with: .allowSelectBlockchain)
            }
            if stringValues.contains("DisablePrecomputedNDEF") {
                mask.update(with: .disablePrecomputedNDEF)
            }
            if stringValues.contains("SkipSecurityDelayIfValidatedByIssuer") {
                mask.update(with: .skipSecurityDelayIfValidatedByIssuer)
            }
            if stringValues.contains("SkipCheckPIN2CVCIfValidatedByIssuer") {
                mask.update(with: .skipCheckPIN2CVCIfValidatedByIssuer)
            }
            if stringValues.contains("SkipSecurityDelayIfValidatedByLinkedTerminal") {
                mask.update(with: .skipSecurityDelayIfValidatedByLinkedTerminal)
            }
            if stringValues.contains("RestrictOverwriteIssuerExtraData") {
                mask.update(with: .restrictOverwriteIssuerExtraData)
            }
            if stringValues.contains("DisableIssuerData") {
                mask.update(with: .disableIssuerData)
            }
            if stringValues.contains("DisableUserData") {
                mask.update(with: .disableUserData)
            }
            if stringValues.contains("DisableFiles") {
                mask.update(with: .disableFiles)
            }
            
            self = mask
        }
        
        func toStringArray() -> [String] {
            var values = [String]()
            if contains(.useActivation) {
                values.append("UseActivation")
            }
            if contains(.useBlock) {
                values.append("UseBlock")
            }
            if contains(.allowSetPIN1) {
                values.append("AllowSetPIN1")
            }
            if contains(.allowSetPIN2) {
                values.append("AllowSetPIN2")
            }
            if contains(.useCvc) {
                values.append("UseCvc")
            }
            if contains(.prohibitDefaultPIN1) {
                values.append("ProhibitDefaultPIN1")
            }
            if contains(.useOneCommandAtTime) {
                values.append("UseOneCommandAtTime")
            }
            if contains(.useNDEF) {
                values.append("UseNDEF")
            }
            if contains(.useDynamicNDEF) {
                values.append("UseDynamicNDEF")
            }
            if contains(.smartSecurityDelay) {
                values.append("SmartSecurityDelay")
            }
            if contains(.allowUnencrypted) {
                values.append("AllowUnencrypted")
            }
            if contains(.allowFastEncryption) {
                values.append("AllowFastEncryption")
            }
            if contains(.protectIssuerDataAgainstReplay) {
                values.append("ProtectIssuerDataAgainstReplay")
            }
            if contains(.allowSelectBlockchain) {
                values.append("AllowSelectBlockchain")
            }
            if contains(.disablePrecomputedNDEF) {
                values.append("DisablePrecomputedNDEF")
            }
            if contains(.skipSecurityDelayIfValidatedByIssuer) {
                values.append("SkipSecurityDelayIfValidatedByIssuer")
            }
            if contains(.skipCheckPIN2CVCIfValidatedByIssuer) {
                values.append("SkipCheckPIN2CVCIfValidatedByIssuer")
            }
            if contains(.skipSecurityDelayIfValidatedByLinkedTerminal) {
                values.append("SkipSecurityDelayIfValidatedByLinkedTerminal")
            }
            if contains(.restrictOverwriteIssuerExtraData) {
                values.append("RestrictOverwriteIssuerExtraData")
            }
            if contains(.disableIssuerData) {
                values.append("DisableIssuerData")
            }
            if contains(.disableUserData) {
                values.append("DisableUserData")
            }
            if contains(.disableFiles) {
                values.append("DisableFiles")
            }
            return values
        }
    }
}

class SettingsMaskBuilder {
    private var settingsMaskValue = 0

    func add(_ settings: Card.Settings.Mask) {
        settingsMaskValue |= settings.rawValue
    }

    func build() -> Card.Settings.Mask {
        return .init(rawValue: settingsMaskValue)
    }
}

extension Card.Settings.Mask {
    func toWalletSettingsMask() -> Card.Wallet.Settings.Mask {
        return .init(rawValue: rawValue)
    }
}
