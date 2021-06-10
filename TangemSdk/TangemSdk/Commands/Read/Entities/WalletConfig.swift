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
	let isProhibitPurge: Bool?
    /// Determines which type of data is required for signing by wallet.
	let signingMethods: SigningMethod?
	
	public init(isProhibitPurge: Bool? = nil, signingMethods: SigningMethod? = nil) {
		self.isProhibitPurge = isProhibitPurge
		self.signingMethods = signingMethods
	}
	
    var settingsMask: Card.Wallet.SettingsMask? {
        guard let isProhibitPurge = isProhibitPurge else { return nil }

		let builder = WalletSettingsMaskBuilder()
		if isProhibitPurge {
			builder.add(.isProhibitPurge)
		}
		return builder.build()
	}
}
