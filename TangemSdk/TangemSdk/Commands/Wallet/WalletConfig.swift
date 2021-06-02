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
    /// If set to `true` wallet will be recreatable, otherwise wallet at purge command will update status to `purge`
	let isReusable: Bool? //todo: waif for DV
    /// If `true` card will denied purge wallet request on this wallet
	let prohibitPurgeWallet: Bool? //todo: rename permanent?
    /// Elliptic curve for wallet.
	let curveId: EllipticCurve?
    /// Determines which type of data is required for signing by wallet.
	let signingMethods: SigningMethod?
	
	public init(isReusable: Bool? = nil, prohibitPurgeWallet: Bool? = nil, curveId: EllipticCurve? = nil, signingMethods: SigningMethod? = nil) {
		self.isReusable = isReusable
		self.prohibitPurgeWallet = prohibitPurgeWallet
		self.curveId = curveId
		self.signingMethods = signingMethods
	}
	
	var settingsMask: WalletSettingsMask? {
        guard isReusable != nil || prohibitPurgeWallet != nil else { return nil }
        //todo: think about it!
		let builder = WalletSettingsMaskBuilder()
		
        if isReusable ?? false { //
			builder.add(.isReusable)
		}
		
		if prohibitPurgeWallet ?? false {
			builder.add(.prohibitPurgeWallet)
		}
		
		return builder.build()
	}
}
