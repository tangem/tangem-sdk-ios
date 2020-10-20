//
//  FileWriteSettings.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/7/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
public enum FileWriteSettings: Hashable, FirmwareRestictible {
	case none, verifiedWithPin2
	
	public var minFirmwareVersion: Double {
		switch self {
		case .none: return 3.29
		case .verifiedWithPin2: return 3.34
		}
	}
	
	public var maxFirmwareVersion: Double {
		switch self {
		case .none, .verifiedWithPin2: return .infinity
		}
	}
}
