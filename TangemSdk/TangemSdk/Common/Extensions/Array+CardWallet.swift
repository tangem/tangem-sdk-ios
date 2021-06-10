//
//  Array+CardWallet.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public extension Array where Element == Card.Wallet {
    subscript(publicKey: Data) -> Element? {
        get {
            return first(where: { $0.publicKey == publicKey })
        }
        set(newValue) {
            guard let index = firstIndex(where: { $0.publicKey == newValue?.publicKey}) else {
                return
            }
            
            if let newValue = newValue {
                self[index] = newValue
            } else {
                remove(at: index)
            }
        }
    }
}

