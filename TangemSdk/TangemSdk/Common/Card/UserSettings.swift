//
//  UserSettings.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 28.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public extension Card {
    struct UserSettings: Codable {
        /// Is allowed to recover user codes
        public internal(set) var isUserCodeRecoveryAllowed: Bool

        /// Is required Pin to open session for v8+ cards
        public internal(set) var isPINRequired: Bool

        /// Is read NDEF feature disabled
        public internal(set) var isNDEFDisabled: Bool
    }
}

extension Card.UserSettings {
    var mask: UserSettingsMask {
        let builder = MaskBuilder<UserSettingsMask>()

        if !isUserCodeRecoveryAllowed {
            builder.add(.forbidResetPIN)
        }

        if isPINRequired {
            builder.add(.requirePIN)
        }

        if isNDEFDisabled {
            builder.add(.disableNDEF)
        }

        return builder.build()
    }

    init(from mask: UserSettingsMask) {
        self.isUserCodeRecoveryAllowed = !mask.contains(.forbidResetPIN)
        self.isPINRequired = mask.contains(.requirePIN)
        self.isNDEFDisabled = mask.contains(.disableNDEF)
    }
}

// MARK: - UserSettingsMask

struct UserSettingsMask: OptionSet, OptionSetCustomStringConvertible {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

extension UserSettingsMask {
    static let forbidResetPIN = UserSettingsMask(rawValue: 0x00000001)
    static let requirePIN = UserSettingsMask(rawValue: 0x00000002)
    static let disableNDEF = UserSettingsMask(rawValue: 0x00000010)
}

// MARK: - OptionSetCodable conformance

extension UserSettingsMask: OptionSetCodable {
    enum OptionKeys: String, OptionKey {
        case forbidResetPIN

        var value: UserSettingsMask {
            switch self {
            case .forbidResetPIN:
                return .forbidResetPIN
            }
        }
    }
}
