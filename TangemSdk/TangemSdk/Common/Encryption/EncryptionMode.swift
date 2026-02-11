//
//  EncryptionMode.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// All available encryption modes
public enum EncryptionMode: String, StringCodable {
    case none
    case fast
    case strong

    /// COS v8+
    case ccmWithSecurityDelay
    case ccmWithAccessToken
    case ccmWithAsymmetricKeys

    var byteValue: Byte {
        switch self {
        case .none:
            0x00
        case .fast:
            0x01
        case .strong:
            0x02
        case .ccmWithSecurityDelay:
            0x10
        case .ccmWithAccessToken:
            0x11
        case .ccmWithAsymmetricKeys:
            0x12
        }
    }

    var aesMode: AesMode {
        switch self {
        case .none:
            AesMode.none
        case .fast:
            AesMode.cbcFast
        case .strong:
            AesMode.cbcStrong
        case .ccmWithSecurityDelay, .ccmWithAccessToken, .ccmWithAsymmetricKeys:
            AesMode.ccm
        }
    }

    var isCCM: Bool {
        aesMode == .ccm
    }
}
