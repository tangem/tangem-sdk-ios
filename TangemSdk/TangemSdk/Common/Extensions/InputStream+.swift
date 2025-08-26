//
//  InputStream+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

extension InputStream {
    func readBytes(count: Int) -> Data? {
        var buffer: [Byte] = Array(repeating: 0x00, count: count)
        let bytesRead = self.read(&buffer, maxLength: count)
        return bytesRead == count ? Data(buffer) : nil
    }
    
    func readByte() -> Byte? {
        return readBytes(count: 1)?.first
    }
}
