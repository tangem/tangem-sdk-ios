//
//  UInt64+.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension UInt64 {
    /// Convert hex data  to Integer
    /// - Parameter hexData: length bytes
    public init(hexData: Data) {
        let value = hexData.reduce(0) { v, byte in
            return v << 8 | UInt64(byte)
        }
        self = value
    }
}
