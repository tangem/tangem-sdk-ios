//
//  Set+FirmwareRestrictible.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/9/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
extension Set where Element: FirmwareRestictible {
	func minFirmwareVersion() -> Double {
		var version = 0.0
		forEach {
			version = Swift.max($0.minFirmwareVersion, version)
		}
		return version
	}
}
