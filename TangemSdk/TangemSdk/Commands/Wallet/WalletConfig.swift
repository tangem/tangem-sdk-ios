//
//  WalletConfig.swift
//  TangemSdk
//
//  Created by Andrew Son on 13/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct WalletData {
	/// Name of the blockchain.
	public let blockchainName: String?
	/// Name of the token.
	public let tokenSymbol: String?
	/// Smart contract address.
	public let tokenContractAddress: String?
	/// Number of decimals in token value.
	public let tokenDecimal: Int?
	
	public init(blockchainName: String?, tokenSymbol: String? = nil, tokenContractAddress: String? = nil, tokenDecimal: Int? = nil) {
		self.blockchainName = blockchainName
		self.tokenSymbol = tokenSymbol
		self.tokenContractAddress = tokenContractAddress
		self.tokenDecimal = tokenDecimal
	}
}

public struct WalletConfig {
	let isReusable: Bool
	let prohibitPurgeWallet: Bool
	let curveId: EllipticCurve
	let signingMethods: SigningMethod
	
	let walletData: WalletData
	
	public init(isReusable: Bool, prohibitPurgeWallet: Bool, curveId: EllipticCurve, signingMethods: SigningMethod, walletData: WalletData) {
		self.isReusable = isReusable
		self.prohibitPurgeWallet = prohibitPurgeWallet
		self.curveId = curveId
		self.signingMethods = signingMethods
		self.walletData = walletData
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
