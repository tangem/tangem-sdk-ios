//
//  AccessLevel.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.

/// COS v8+
enum AccessLevel: Int {
    case publicAccess = 0x01
    case publicSecureChannel = 0x02
    case user = 0x04
    case issuer = 0x08
    case fileOwner = 0x10
    case backupCard = 0x20
}
