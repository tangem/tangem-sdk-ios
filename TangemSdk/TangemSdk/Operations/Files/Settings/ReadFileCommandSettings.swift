//
//  ActionSettings.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Settings that should be applied in `ReadFileCommand`
@available (iOS 13.0, *)
public enum ReadFileCommandSettings: FirmwareRestrictable {
    case checkFileValidationHash
    
    public var minFirmwareVersion: FirmwareVersion {
        switch self {
        case .checkFileValidationHash: return FirmwareVersion(major: 3, minor: 34)
        }
    }
    
    public var maxFirmwareVersion: FirmwareVersion {
        switch self {
        case .checkFileValidationHash: return .max
        }
    }
}
