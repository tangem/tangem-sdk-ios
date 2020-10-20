//
//  FirmwareRestrictible.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/9/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
public protocol FirmwareRestictible {
	var minFirmwareVersion: Double { get }
	var maxFirmwareVersion: Double { get }
}
