//
//  Array+CardWallet.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public extension Array where Element == Card.Wallet {
    subscript(publicKey: Data) -> Element? {
        get {
            return first(where: { $0.publicKey == publicKey })
        }
        set(newValue) {
            let index = firstIndex(where: { $0.publicKey == publicKey })
            
            if let newValue = newValue {
                if let index = index {
                    self[index] = newValue
                } else {
                    self.append(newValue)
                }
            } else {
                if let index = index {
                    remove(at: index)
                }
            }
        }
    }
}
