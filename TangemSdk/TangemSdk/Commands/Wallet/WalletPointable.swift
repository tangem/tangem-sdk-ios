//
//  WalletPointable.swift
//  TangemSdk
//
//  Created by Andrew Son on 13/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Use this to identify that CardSessionRunnable type can point to specific wallet to interact with
///	- Note: Available for cards with COS v.4.0 and higher
@available(iOS 13.0, *)
public protocol WalletPointable {
	var pointer: WalletPointer? { get }
}

/// Pointer to specific wallet for interaction
///
/// Currently available two type of pointers: `WalletIndexPointer` and `WalletPublicKeyPointer`
/// - Note: Available for cards with COS v.4.0 and higher
@available(iOS 13.0, *)
public protocol WalletPointer {
	@discardableResult
	func addTlvData(_ tlvBuilder: TlvBuilder) throws -> TlvBuilder
}

/// Pointer to wallet by index.
/// - Note: Available for cards with COS v.4.0 and higher
public struct WalletIndexPointer: WalletPointer {
	private(set) var index: Int
	
	public init(index: Int) {
		self.index = index
	}
	
	@discardableResult
	public func addTlvData(_ tlvBuilder: TlvBuilder) throws -> TlvBuilder {
		try tlvBuilder.append(.walletIndex, value: index)
	}
}

/// Pointer to wallet by wallet public key
/// - Note: Available for cards with COS v.4.0 and higher
public struct WalletPublicKeyPointer: WalletPointer {
	private(set) var publicKey: Data
	
	public init(publicKey: Data) {
		self.publicKey = publicKey
	}
	
	@discardableResult
	public func addTlvData(_ tlvBuilder: TlvBuilder) throws -> TlvBuilder {
		try tlvBuilder.append(.walletPublicKey, value: publicKey)
	}
}
