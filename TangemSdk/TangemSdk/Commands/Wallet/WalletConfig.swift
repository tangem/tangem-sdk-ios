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
	let isReusable: Bool
	let prohibitPurgeWallet: Bool
	let curveId: EllipticCurve
	let signingMethods: SigningMethod
	
	public init(isReusable: Bool, prohibitPurgeWallet: Bool, curveId: EllipticCurve, signingMethods: SigningMethod) {
		self.isReusable = isReusable
		self.prohibitPurgeWallet = prohibitPurgeWallet
		self.curveId = curveId
		self.signingMethods = signingMethods
	}
	
	var settingsMask: WalletSettingsMask {
		let builder = WalletSettingsMaskBuilder()
		
		if isReusable {
			builder.add(.isReusable)
		}
		
		if prohibitPurgeWallet {
			builder.add(.prohibitPurgeWallet)
		}
		
		return builder.build()
	}
}
