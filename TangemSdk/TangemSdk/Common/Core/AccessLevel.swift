//
//  AccessLevel.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 29/09/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.

/// COS v8+
enum AccessLevel: Int, Comparable {
    case publicAccess = 0x01
    case publicSecureChannel = 0x02
    case user = 0x04
    case issuer = 0x08
    case fileOwner = 0x10
    case backupCard = 0x20

    /// Privilege tier for ordering: publicAccess < publicSecureChannel < user-level (user, issuer, fileOwner, backupCard)
    private var privilegeTier: Int {
        switch self {
        case .publicAccess: return 0
        case .publicSecureChannel: return 1
        case .user, .issuer, .fileOwner, .backupCard: return 2
        }
    }

    static func < (lhs: AccessLevel, rhs: AccessLevel) -> Bool {
        lhs.privilegeTier < rhs.privilegeTier
    }
}
