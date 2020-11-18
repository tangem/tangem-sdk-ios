//
//  ActionSettings.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
public enum ReadFileCommandSettings: FirmwareRestictible {
	case checkFileValidationHash
	
	public var minFirmwareVersion: FirmwareVersion {
		switch self {
		case .checkFileValidationHash: return FirmwareVersion(version: "3.34")
		}
	}
	
	public var maxFirmwareVersion: FirmwareVersion {
		switch self {
		case .checkFileValidationHash: return .max
		}
	}
}
