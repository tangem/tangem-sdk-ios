//
//  Int+.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 27/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public extension Int {
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
        let data = withUnsafeBytes(of: bigEndian) { Data($0) }
        return data
    }

    /// Converts an integer to big-endian bytes of the specified count.
    func toBytes(count: Int) -> Data {
        let data = withUnsafeBytes(of: bigEndian) { Data($0) }
        return data.suffix(count)
    }
}

public extension UInt64 {
    var bytes8LE: Data {
        let data = withUnsafeBytes(of: self) { Data($0) }
        return data
    }
}

public extension UInt32 {
    var bytes4: Data {
        let data = withUnsafeBytes(of: bigEndian) { Data($0) }
        return data
    }
}
