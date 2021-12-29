//
//  Array+ExtendedPublicKey.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.12.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public extension Array where Element == ExtendedPublicKey {
    subscript(derivationPath: DerivationPath) -> Element? {
        get {
            return first(where: { $0.derivationPath == derivationPath })
        }
        
        set(newValue) {
            let index = firstIndex(where: { $0.derivationPath == derivationPath })
            
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
