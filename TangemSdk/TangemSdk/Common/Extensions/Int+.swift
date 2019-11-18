//
//  Int+.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 27/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

extension Int {
    /// Convert hex data  to Integer
    /// - Parameter hexData: length bytes
    init(hexData: Data) {
        let value = hexData.reduce(0) { v, byte in
            return v << 8 | Int(byte)
        }
        self = value
    }
    
    /// Convert int to byte, truncatingIfNeeded
    var byte: Data {
        return Data([Byte(truncatingIfNeeded: self)])
    }
    
    /// return 2 bytes of integer. BigEndian format
    var bytes2: Data {
        let clamped = UInt16(clamping: self).bigEndian
        let data = withUnsafeBytes(of: clamped) { Data($0) }
        return data
    }
    
    /// return 4 bytes of integer. BigEndian format
    var bytes4: Data {
        let clamped = UInt32(clamping: self).bigEndian
        let data = withUnsafeBytes(of: clamped) { Data($0) }
        return data
    }
    
    /// return 8 bytes of integer. BigEndian  format
    var bytes8: Data {
        let data = withUnsafeBytes(of: self.bigEndian) { Data($0) }
        return data
    }
}
