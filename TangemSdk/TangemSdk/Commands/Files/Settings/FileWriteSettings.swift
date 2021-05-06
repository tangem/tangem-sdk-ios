//
//  FileWriteSettings.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/7/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Settings that will be used while writing files on card
@available (iOS 13.0, *)
public enum FileWriteSettings: Hashable, FirmwareRestictible {
	case none, verifiedWithPin2
	
	public var minFirmwareVersion: FirmwareVersion {
		switch self {
		case .none: return FirmwareVersion(major: 3, minor: 29)
		case .verifiedWithPin2: return FirmwareVersion(major: 3, minor: 34)
		}
	}
	
	public var maxFirmwareVersion: FirmwareVersion {
		switch self {
		case .none, .verifiedWithPin2: return .max
		}
	}
}
