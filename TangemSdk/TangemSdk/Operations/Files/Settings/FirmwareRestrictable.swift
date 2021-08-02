//
//  FirmwareRestrictable.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Protocol that determines what firmware versions will be capable for performing command
@available (iOS 13.0, *)
public protocol FirmwareRestrictable {
	var minFirmwareVersion: FirmwareVersion { get }
	var maxFirmwareVersion: FirmwareVersion { get }
}
