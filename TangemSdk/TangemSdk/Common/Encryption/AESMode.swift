//
//  AESMode.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 29/09/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.

/// AES encryption modes
enum AesMode {
    case none
    case cbcFast
    case cbcStrong
    case ccm

    var byteValue: Byte {
        switch self {
        case .none:
            0x00
        case .cbcFast:
            0x01
        case .cbcStrong:
            0x02
        case .ccm:
            0x10
        }
    }
}
