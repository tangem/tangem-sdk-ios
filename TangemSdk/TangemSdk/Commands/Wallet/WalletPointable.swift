//
//  WalletPointable.swift
//  TangemSdk
//
//  Created by Andrew Son on 13/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation


/// Index to specific wallet for interaction
/// - Note: Available for cards with COS v.4.0 and higher
@available(iOS 13.0, *)
public enum WalletIndex {
	case index(Int), publicKey(Data)
	
	@discardableResult
	public func addTlvData(to tlvBuilder: TlvBuilder) throws -> TlvBuilder {
		switch self {
		case .index(let index):
			return try tlvBuilder.append(.walletIndex, value: index)
		case .publicKey(let key):
			return try tlvBuilder.append(.walletPublicKey, value: key)
		}
	}
}
