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
    struct Mask: OptionSet, JSONStringConvertible, OptionSetCustomStringConvertible {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
}

//MARK:- Constants
public extension Card.Settings.Mask {
    static let useActivation = Card.Settings.Mask(rawValue: 0x0002)
    static let useBlock = Card.Settings.Mask(rawValue: 0x0008)
    static let allowSetPIN1 = Card.Settings.Mask(rawValue: 0x0010)
    static let allowSetPIN2 = Card.Settings.Mask(rawValue: 0x0020)
    static let useCvc = Card.Settings.Mask(rawValue: 0x0040)
    static let prohibitDefaultPIN1 = Card.Settings.Mask(rawValue: 0x0080)
    static let useOneCommandAtTime = Card.Settings.Mask(rawValue: 0x0100)
    static let useNDEF = Card.Settings.Mask(rawValue: 0x0200)
    static let useDynamicNDEF = Card.Settings.Mask(rawValue: 0x0400)
    static let smartSecurityDelay = Card.Settings.Mask(rawValue: 0x0800)
    static let allowUnencrypted = Card.Settings.Mask(rawValue: 0x1000)
    static let allowFastEncryption = Card.Settings.Mask(rawValue: 0x2000)
    static let protectIssuerDataAgainstReplay = Card.Settings.Mask(rawValue: 0x4000)
    static let allowSelectBlockchain = Card.Settings.Mask(rawValue: 0x8000)
    static let disablePrecomputedNDEF = Card.Settings.Mask(rawValue: 0x00010000)
    static let skipSecurityDelayIfValidatedByIssuer = Card.Settings.Mask(rawValue: 0x00020000)
    static let skipCheckPIN2CVCIfValidatedByIssuer = Card.Settings.Mask(rawValue: 0x00040000)
    static let skipSecurityDelayIfValidatedByLinkedTerminal = Card.Settings.Mask(rawValue: 0x00080000)
    static let restrictOverwriteIssuerExtraData = Card.Settings.Mask(rawValue: 0x00100000)
    static let disableIssuerData = Card.Settings.Mask(rawValue: 0x01000000)
    static let disableUserData = Card.Settings.Mask(rawValue: 0x02000000)
    static let disableFiles = Card.Settings.Mask(rawValue: 0x04000000)
    static let permanentWallet = Card.Settings.Mask(rawValue: 0x0004)
}

extension Card.Settings.Mask {
    static let isReusable = Card.Settings.Mask(rawValue: 0x0001)
}

//MARK:- OptionSetCodable conformance
extension Card.Settings.Mask: OptionSetCodable {
    public enum OptionKeys: String, OptionKey {
        case useActivation
        case useBlock
        case allowSetPIN1
        case allowSetPIN2
        case useCvc
        case prohibitDefaultPIN1
        case useOneCommandAtTime
        case useNDEF
        case useDynamicNDEF
        case smartSecurityDelay
        case allowUnencrypted
        case allowFastEncryption
        case protectIssuerDataAgainstReplay
        case allowSelectBlockchain
        case disablePrecomputedNDEF
        case skipSecurityDelayIfValidatedByIssuer
        case skipCheckPIN2CVCIfValidatedByIssuer
        case skipSecurityDelayIfValidatedByLinkedTerminal
        case restrictOverwriteIssuerExtraData
        case disableIssuerData
        case disableUserData
        case disableFiles
        case isReusable
        case prohibitPurgeWallet
        
        public var value: Card.Settings.Mask {
            switch self {
            case .useActivation:
                return .useActivation
            case .useBlock:
                return .useBlock
            case .allowSetPIN1:
                return .allowSetPIN1
            case .allowSetPIN2:
                return .allowSetPIN2
            case .useCvc:
                return .useCvc
            case .prohibitDefaultPIN1:
                return .prohibitDefaultPIN1
            case .useOneCommandAtTime:
                return .useOneCommandAtTime
            case .useNDEF:
                return .useNDEF
            case .useDynamicNDEF:
                return .useDynamicNDEF
            case .smartSecurityDelay:
                return .smartSecurityDelay
            case .allowUnencrypted:
                return .allowUnencrypted
            case .allowFastEncryption:
                return .allowFastEncryption
            case .protectIssuerDataAgainstReplay:
                return .protectIssuerDataAgainstReplay
            case .allowSelectBlockchain:
                return .allowSelectBlockchain
            case .disablePrecomputedNDEF:
                return .disablePrecomputedNDEF
            case .skipSecurityDelayIfValidatedByIssuer:
                return .skipSecurityDelayIfValidatedByIssuer
            case .skipCheckPIN2CVCIfValidatedByIssuer:
                return .skipCheckPIN2CVCIfValidatedByIssuer
            case .skipSecurityDelayIfValidatedByLinkedTerminal:
                return .skipSecurityDelayIfValidatedByLinkedTerminal
            case .restrictOverwriteIssuerExtraData:
                return .restrictOverwriteIssuerExtraData
            case .disableIssuerData:
                return .disableIssuerData
            case .disableUserData:
                return .disableUserData
            case .disableFiles:
                return .disableFiles
            case .isReusable:
                return .isReusable
            case .prohibitPurgeWallet:
                return .permanentWallet
            }
        }
    }
}

extension Card.Settings.Mask {
    func toWalletSettingsMask() -> Card.Wallet.Settings.Mask {
        return .init(rawValue: rawValue)
    }
}
