//
//  ByteUtilsTest.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class ByteUtilsTests: XCTestCase {
    func testHexConversion() {
        let testData = UInt8(0x1B)
        let testString = "1B"
        XCTAssert(testString == testData.hexString)
    }

    func testInputStream() throws {
        let data = Data(hexString: "00010203040506")
        let inputStream = InputStream(data: data)
        inputStream.open()
        let bytes = try XCTUnwrap(inputStream.readBytes(count: 4))
        XCTAssertEqual(bytes, Data(hexString: "00010203"))
        let oneMoreByte = try XCTUnwrap(inputStream.readByte())
        XCTAssertEqual(oneMoreByte, UInt8(0x04))
        inputStream.close()
    }

    func testParseBits() throws {
        let testCases = ["10110111", "00000000", "11111111", "10000000", "00000001"]

        for testcase in testCases {
            let byte = try XCTUnwrap(UInt8(testcase, radix: 2))
            let bits = byte.toBits().joined()
            XCTAssertEqual(bits, testcase)
        }
    }

    // MARK: - UInt16

    func testUInt16HexString() {
        XCTAssertEqual(UInt16(0x00FF).hexString, "FF")
        XCTAssertEqual(UInt16(0x0100).hexString, "100")
        XCTAssertEqual(UInt16(0xFFFF).hexString, "FFFF")
        XCTAssertEqual(UInt16(0).hexString, "00")
    }

    func testUInt16Description() {
        let value: UInt16 = 0xABCD
        XCTAssertEqual(value.description, value.hexString)
    }

    // MARK: - UInt8 description

    func testUInt8Description() {
        let value: UInt8 = 0x0F
        XCTAssertEqual(value.description, "0F")
    }

    // MARK: - [UInt8] hash functions

    func testByteArraySHA256() {
        let bytes: [UInt8] = Array("abc".utf8)
        let hash = bytes.getSHA256()
        let expected = Data("abc".utf8).getSHA256()
        XCTAssertEqual(hash, expected)
    }

    func testByteArraySHA512() {
        let bytes: [UInt8] = Array("abc".utf8)
        let hash = bytes.getSHA512()
        let expected = Data("abc".utf8).getSHA512()
        XCTAssertEqual(hash, expected)
    }

    func testByteArrayDoubleSHA256() {
        let bytes: [UInt8] = Array("abc".utf8)
        let hash = bytes.getDoubleSHA256()
        let expected = Data("abc".utf8).getDoubleSHA256()
        XCTAssertEqual(hash, expected)
    }
}
