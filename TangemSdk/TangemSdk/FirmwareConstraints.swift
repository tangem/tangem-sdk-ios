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
		static let walletData = 4.0
		static let pin2IsDefault = 4.0
		static let files = 3.29
	}
	
	struct DeprecationVersions {
		static let walletRemainingSignatures = 4.0
	}
	
}
