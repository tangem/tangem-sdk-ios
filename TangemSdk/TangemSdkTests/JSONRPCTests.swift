//
//  JSONRPCTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 21.05.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class JSONRPCTests: XCTestCase {
    func testDecodeSingleHex() {
        var dict: [String: String] = .init()
        dict["pubKey"] = "{\"AABBCCDDEEFF\"}"
        let data: Data = try! dict.value(for: "pubKey")
        XCTAssert(data == Data(hexString: "AABBCCDDEEFF"))
    }
    
    func testDecodeMultipleHex() {
        var dict: [String: String] = .init()
        let strings = ["AABBCCDDEEFF", "AABBCCDDEEFFGG"]
        let json = try! JSONEncoder().encode(strings)
        dict["hashes"] = String(data: json, encoding: .utf8)
        let data: [Data] = try! dict.value(for: "hashes")
        XCTAssert(data[0] == Data(hexString: "AABBCCDDEEFF"))
        XCTAssert(data[1] == Data(hexString: "AABBCCDDEEFFGG"))
    }
}
