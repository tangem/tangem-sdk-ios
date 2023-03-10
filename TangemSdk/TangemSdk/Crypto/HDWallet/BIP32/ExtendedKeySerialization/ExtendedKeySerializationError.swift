//
//  ExtendedKeySerializationError.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExtendedKeySerializationError: String, Error, LocalizedError {
    case wrongLength
    case decodingFailed
    case wrongVersion
    case wrongKey

    public var errorDescription: String? { rawValue }
}
