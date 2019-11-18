//
//  ByteUtilsTest.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 01.11.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class ByteUtilsTests: XCTestCase {
    func testHexConversion() {
        let testData = UInt8(0x1B)
        let testString = "1B"
        XCTAssert(testString == testData.toHex())
    }
    
    func testInputStream() {
        let data = Data(hex: "00010203040506")
        let inputStream = InputStream(data: data)
        inputStream.open()
        let bytes = inputStream.readBytes(count: 4)
        XCTAssertNotNil(bytes)
        XCTAssertEqual(bytes!, Data(hex: "00010203"))
        let oneMoreByte = inputStream.readByte()
        XCTAssertNotNil(oneMoreByte)
        XCTAssertEqual(oneMoreByte!, UInt8(0x04))
        inputStream.close()
    }
}
