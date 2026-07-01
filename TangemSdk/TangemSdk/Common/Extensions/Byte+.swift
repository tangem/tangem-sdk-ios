//
//  Byte+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

public typealias Byte = UInt8

public extension UInt8 {
    var description: String {
        return hexString
    }

    var hexString: String {
        return String(format: "%02X", self)
    }

    internal func toBits() -> [String] {
        let totalBitsCount = 8

        var bits = [String](repeating: "0", count: totalBitsCount)

        for index in 0 ..< totalBitsCount {
            let mask: UInt8 = 1 << UInt8(totalBitsCount - 1 - index)
            let currentBit = self & mask

            if currentBit != 0 {
                bits[index] = "1"
            }
        }

        return bits
    }
}

public extension UInt16 {
    var description: String {
        return hexString
    }

    var hexString: String {
        return String(format: "%02X", self)
    }
}

public extension Array where Element == UInt8 {
    func getSHA256() -> Data {
        let digest = SHA256.hash(data: self)
        return Data(digest)
    }

    func getSHA512() -> Data {
        let digest = SHA512.hash(data: self)
        return Data(digest)
    }

    func getDoubleSHA256() -> Data {
        return getSHA256().getSHA256()
    }
}
