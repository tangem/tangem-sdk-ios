//
//  FirmwareConstraints.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/8/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// List of card  firmware constraints. Use this information for checking if certain functionality available on scanned card or not
public enum FirmwareConstraints {
	
    public enum AvailabilityVersions {
        /// Multi-wallet
        public static let walletData = FirmwareVersion(major: 4, minor: 0)
        /// Field on card that describes is pin2 is default value or not
        public static let pin2IsDefault = FirmwareVersion(major: 4, minor: 1)
        public static let files = FirmwareVersion(major: 3, minor: 29)
	}
	
    public enum DeprecationVersions {
        public static let walletRemainingSignatures = FirmwareVersion(major: 4, minor: 0)
	}
	
}
