//
//  Card.Settings.Mask.swift
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
        
        public static let useActivation = Card.Settings.Mask(rawValue: 0x0002)
        public static let useBlock = Card.Settings.Mask(rawValue: 0x0008)
        public static let allowSetPIN1 = Card.Settings.Mask(rawValue: 0x0010)
        public static let allowSetPIN2 = Card.Settings.Mask(rawValue: 0x0020)
        public static let useCvc = Card.Settings.Mask(rawValue: 0x0040)
        public static let prohibitDefaultPIN1 = Card.Settings.Mask(rawValue: 0x0080)
        public static let useOneCommandAtTime = Card.Settings.Mask(rawValue: 0x0100)
        public static let useNDEF = Card.Settings.Mask(rawValue: 0x0200)
        public static let useDynamicNDEF = Card.Settings.Mask(rawValue: 0x0400)
        public static let smartSecurityDelay = Card.Settings.Mask(rawValue: 0x0800)
        public static let allowUnencrypted = Card.Settings.Mask(rawValue: 0x1000)
        public static let allowFastEncryption = Card.Settings.Mask(rawValue: 0x2000)
        public static let protectIssuerDataAgainstReplay = Card.Settings.Mask(rawValue: 0x4000)
        public static let allowSelectBlockchain = Card.Settings.Mask(rawValue: 0x8000)
        public static let disablePrecomputedNDEF = Card.Settings.Mask(rawValue: 0x00010000)
        public static let skipSecurityDelayIfValidatedByIssuer = Card.Settings.Mask(rawValue: 0x00020000)
        public static let skipCheckPIN2CVCIfValidatedByIssuer = Card.Settings.Mask(rawValue: 0x00040000)
        public static let skipSecurityDelayIfValidatedByLinkedTerminal = Card.Settings.Mask(rawValue: 0x00080000)
        public static let restrictOverwriteIssuerExtraData = Card.Settings.Mask(rawValue: 0x00100000)
        public static let disableIssuerData = Card.Settings.Mask(rawValue: 0x01000000)
        public static let disableUserData = Card.Settings.Mask(rawValue: 0x02000000)
        public static let disableFiles = Card.Settings.Mask(rawValue: 0x04000000)
        
        static let isReusable = Card.Settings.Mask(rawValue: 0x0001)
        static let prohibitPurgeWallet = Card.Settings.Mask(rawValue: 0x0004)
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(toStringArray())
        }
        
        public init(from decoder: Decoder) throws {
            let values = try decoder.singleValueContainer()
            let stringValues = try values.decode([String].self)
            var mask = Card.Settings.Mask()
            
            if stringValues.contains("UseActivation") {
                mask.update(with: Card.Settings.Mask.useActivation)
            }
            if stringValues.contains("UseBlock") {
                mask.update(with: Card.Settings.Mask.useBlock)
            }
            if stringValues.contains("AllowSetPIN1") {
                mask.update(with: Card.Settings.Mask.allowSetPIN1)
            }
            if stringValues.contains("AllowSetPIN2") {
                mask.update(with: Card.Settings.Mask.allowSetPIN2)
            }
            if stringValues.contains("UseCvc") {
                mask.update(with: Card.Settings.Mask.useCvc)
            }
            if stringValues.contains("ProhibitDefaultPIN1") {
                mask.update(with: Card.Settings.Mask.prohibitDefaultPIN1)
            }
            if stringValues.contains("UseOneCommandAtTime") {
                mask.update(with: Card.Settings.Mask.useOneCommandAtTime)
            }
            if stringValues.contains("UseNDEF") {
                mask.update(with: Card.Settings.Mask.useNDEF)
            }
            if stringValues.contains("UseDynamicNDEF") {
                mask.update(with: Card.Settings.Mask.useDynamicNDEF)
            }
            if stringValues.contains("SmartSecurityDelay") {
                mask.update(with: Card.Settings.Mask.smartSecurityDelay)
            }
            if stringValues.contains("AllowUnencrypted") {
                mask.update(with: Card.Settings.Mask.allowUnencrypted)
            }
            if stringValues.contains("AllowFastEncryption") {
                mask.update(with: Card.Settings.Mask.allowFastEncryption)
            }
            if stringValues.contains("ProtectIssuerDataAgainstReplay") {
                mask.update(with: Card.Settings.Mask.protectIssuerDataAgainstReplay)
            }
            if stringValues.contains("AllowSelectBlockchain") {
                mask.update(with: Card.Settings.Mask.allowSelectBlockchain)
            }
            if stringValues.contains("DisablePrecomputedNDEF") {
                mask.update(with: Card.Settings.Mask.disablePrecomputedNDEF)
            }
            if stringValues.contains("SkipSecurityDelayIfValidatedByIssuer") {
                mask.update(with: Card.Settings.Mask.skipSecurityDelayIfValidatedByIssuer)
            }
            if stringValues.contains("SkipCheckPIN2CVCIfValidatedByIssuer") {
                mask.update(with: Card.Settings.Mask.skipCheckPIN2CVCIfValidatedByIssuer)
            }
            if stringValues.contains("SkipSecurityDelayIfValidatedByLinkedTerminal") {
                mask.update(with: Card.Settings.Mask.skipSecurityDelayIfValidatedByLinkedTerminal)
            }
            if stringValues.contains("RestrictOverwriteIssuerExtraData") {
                mask.update(with: Card.Settings.Mask.restrictOverwriteIssuerExtraData)
            }
            if stringValues.contains("DisableIssuerData") {
                mask.update(with: Card.Settings.Mask.disableIssuerData)
            }
            if stringValues.contains("DisableUserData") {
                mask.update(with: Card.Settings.Mask.disableUserData)
            }
            if stringValues.contains("DisableFiles") {
                mask.update(with: Card.Settings.Mask.disableFiles)
            }
            
            self = mask
        }
        
        func toStringArray() -> [String] {
            var values = [String]()
            if contains(Card.Settings.Mask.useActivation) {
                values.append("UseActivation")
            }
            if contains(Card.Settings.Mask.useBlock) {
                values.append("UseBlock")
            }
            if contains(Card.Settings.Mask.allowSetPIN1) {
                values.append("AllowSetPIN1")
            }
            if contains(Card.Settings.Mask.allowSetPIN2) {
                values.append("AllowSetPIN2")
            }
            if contains(Card.Settings.Mask.useCvc) {
                values.append("UseCvc")
            }
            if contains(Card.Settings.Mask.prohibitDefaultPIN1) {
                values.append("ProhibitDefaultPIN1")
            }
            if contains(Card.Settings.Mask.useOneCommandAtTime) {
                values.append("UseOneCommandAtTime")
            }
            if contains(Card.Settings.Mask.useNDEF) {
                values.append("UseNDEF")
            }
            if contains(Card.Settings.Mask.useDynamicNDEF) {
                values.append("UseDynamicNDEF")
            }
            if contains(Card.Settings.Mask.smartSecurityDelay) {
                values.append("SmartSecurityDelay")
            }
            if contains(Card.Settings.Mask.allowUnencrypted) {
                values.append("AllowUnencrypted")
            }
            if contains(Card.Settings.Mask.allowFastEncryption) {
                values.append("AllowFastEncryption")
            }
            if contains(Card.Settings.Mask.protectIssuerDataAgainstReplay) {
                values.append("ProtectIssuerDataAgainstReplay")
            }
            if contains(Card.Settings.Mask.allowSelectBlockchain) {
                values.append("AllowSelectBlockchain")
            }
            if contains(Card.Settings.Mask.disablePrecomputedNDEF) {
                values.append("DisablePrecomputedNDEF")
            }
            if contains(Card.Settings.Mask.skipSecurityDelayIfValidatedByIssuer) {
                values.append("SkipSecurityDelayIfValidatedByIssuer")
            }
            if contains(Card.Settings.Mask.skipCheckPIN2CVCIfValidatedByIssuer) {
                values.append("SkipCheckPIN2CVCIfValidatedByIssuer")
            }
            if contains(Card.Settings.Mask.skipSecurityDelayIfValidatedByLinkedTerminal) {
                values.append("SkipSecurityDelayIfValidatedByLinkedTerminal")
            }
            if contains(Card.Settings.Mask.restrictOverwriteIssuerExtraData) {
                values.append("RestrictOverwriteIssuerExtraData")
            }
            if contains(Card.Settings.Mask.disableIssuerData) {
                values.append("DisableIssuerData")
            }
            if contains(Card.Settings.Mask.disableUserData) {
                values.append("DisableUserData")
            }
            if contains(Card.Settings.Mask.disableFiles) {
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
        return Card.Settings.Mask(rawValue: settingsMaskValue)
    }
}

extension Card.Settings.Mask {
    func toWalletSettingsMask() -> Card.Wallet.SettingsMask {
        return Card.Wallet.SettingsMask(rawValue: rawValue)
    }
}
