//
//  .swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public typealias CardSettingsMask = Card.Settings.Mask

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
public extension CardSettingsMask {
    static let useActivation = CardSettingsMask(rawValue: 0x0002)
    static let useBlock = CardSettingsMask(rawValue: 0x0008)
    static let allowSetPIN1 = CardSettingsMask(rawValue: 0x0010) //nado
    static let allowSetPIN2 = CardSettingsMask(rawValue: 0x0020) //nado
    static let useCvc = CardSettingsMask(rawValue: 0x0040)
    static let prohibitDefaultPIN1 = CardSettingsMask(rawValue: 0x0080) //nado
    static let useOneCommandAtTime = CardSettingsMask(rawValue: 0x0100)
    static let useNDEF = CardSettingsMask(rawValue: 0x0200)
    static let useDynamicNDEF = CardSettingsMask(rawValue: 0x0400)
    static let smartSecurityDelay = CardSettingsMask(rawValue: 0x0800)
    static let allowUnencrypted = CardSettingsMask(rawValue: 0x1000) //nado enum  { none, fast, strong }
    static let allowFastEncryption = CardSettingsMask(rawValue: 0x2000) //nado ->
    static let protectIssuerDataAgainstReplay = CardSettingsMask(rawValue: 0x4000) //nado internal (skip json)
    static let allowSelectBlockchain = CardSettingsMask(rawValue: 0x8000) //nado internal (skip json)
    static let disablePrecomputedNDEF = CardSettingsMask(rawValue: 0x00010000)
    static let skipSecurityDelayIfValidatedByIssuer = CardSettingsMask(rawValue: 0x00020000)
    static let skipCheckPIN2CVCIfValidatedByIssuer = CardSettingsMask(rawValue: 0x00040000)
    static let skipSecurityDelayIfValidatedByLinkedTerminal = CardSettingsMask(rawValue: 0x00080000) //nado isLinkedTerminalEnabled
    static let restrictOverwriteIssuerExtraData = CardSettingsMask(rawValue: 0x00100000) //nado
    static let disableIssuerData = CardSettingsMask(rawValue: 0x01000000) //todo: precheck?
    static let disableUserData = CardSettingsMask(rawValue: 0x02000000) //todo: precheck?
    static let disableFiles = CardSettingsMask(rawValue: 0x04000000) //todo: precheck?
    static let permanentWallet = CardSettingsMask(rawValue: 0x0004) //nado internal (skip json)
}

extension CardSettingsMask {
    static let isReusable = CardSettingsMask(rawValue: 0x0001)
}

//MARK:- OptionSetCodable conformance
extension CardSettingsMask: OptionSetCodable {
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
        
        public var value: CardSettingsMask {
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

extension CardSettingsMask {
    func toWalletSettingsMask() -> WalletSettingsMask {
        return .init(rawValue: rawValue)
    }
}
