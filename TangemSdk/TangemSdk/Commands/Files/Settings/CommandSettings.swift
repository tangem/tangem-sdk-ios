//
//  ActionSettings.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/9/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
public enum ReadCommandSettings: FirmwareRestictible {
	case checkFileValidationHash
	
	public var minFirmwareVersion: Double {
		switch self {
		case .checkFileValidationHash: return 3.34
		}
	}
	
	public var maxFirmwareVersion: Double {
		switch self {
		case .checkFileValidationHash: return .infinity
		}
	}
}
