//
//  FirmwareConstraints.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/8/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct FirmwareConstraints {
	
	struct AvailabilityVersions {
		static let walletData = FirmwareVersion(major: 4, minor: 0)
		static let pin2IsDefault = FirmwareVersion(major: 4, minor: 0)
		static let files = FirmwareVersion(major: 3, minor: 29)
	}
	
	struct DeprecationVersions {
		static let walletRemainingSignatures = FirmwareVersion(major: 4, minor: 0)
	}
	
}
