//
//  WalletConfig.swift
//  TangemSdk
//
//  Created by Andrew Son on 13/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Configuration for `CreateWalletCommand`. This config will override default settings saved on card
public struct WalletConfig {
    /// If `true` card will denied purge wallet request on this wallet
	let isReadOnly: Bool?
    /// Elliptic curve for wallet.
	let curve: EllipticCurve?
    /// Determines which type of data is required for signing by wallet.
	let signingMethods: SigningMethod?
	
	public init(isReadOnly: Bool? = nil, curve: EllipticCurve? = nil, signingMethods: SigningMethod? = nil) {
		self.isReadOnly = isReadOnly
		self.curve = curve
		self.signingMethods = signingMethods
	}
	
	var settingsMask: WalletSettingsMask? {
        guard let isReadOnly = isReadOnly else { return nil }

		let builder = WalletSettingsMaskBuilder()
		if isReadOnly {
			builder.add(.isReadOnly)
		}
		return builder.build()
	}
}
