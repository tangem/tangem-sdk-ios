//
//  UserSettings.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 28.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public extension Card {
    struct UserSettings: Codable {
        /// Is allowed to reset user codes
        public internal(set) var isResettingUserCodesAllowed: Bool
    }
}

@available(iOS 13.0, *)
extension Card.UserSettings {
    var mask: UserSettingsMask {
        let builder = MaskBuilder<UserSettingsMask>()

        if !isResettingUserCodesAllowed {
            builder.add(.forbidResetPIN)
        }

        return builder.build()
    }

    init(from mask: UserSettingsMask) {
        self.isResettingUserCodesAllowed = !mask.contains(.forbidResetPIN)
    }
}

// MARK: - UserSettingsMask

@available(iOS 13.0, *)
struct UserSettingsMask: OptionSet, OptionSetCustomStringConvertible {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

@available(iOS 13.0, *)
extension UserSettingsMask {
    static let forbidResetPIN = UserSettingsMask(rawValue: 0x00000001)
}

// MARK: - OptionSetCodable conformance

@available(iOS 13.0, *)
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
