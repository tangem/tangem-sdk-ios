//
//  FirmwareRestrictible.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
public protocol FirmwareRestictible {
	var minFirmwareVersion: FirmwareVersion { get }
	var maxFirmwareVersion: FirmwareVersion { get }
}
