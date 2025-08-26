//
//  EncryptionMode.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// All available encryption modes
public enum EncryptionMode: String, StringCodable {
    case none
    case fast
    case strong
    
    var byteValue: Byte {
        switch self {
        case .none:
            return 0x00
        case .fast:
            return 0x01
        case .strong:
            return 0x02
        }
    }
}
