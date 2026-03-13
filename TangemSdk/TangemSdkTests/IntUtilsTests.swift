//
//  IntUtilsTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 01.11.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class IntUtilsTests: XCTestCase {
    func testFromHexConversion() {
        let testData = Data(hexString: "9569")
        XCTAssertEqual(38249, Int(hexData: testData))
    }

    func testFromHexConversionOverflow() {
        let testData = Data(hexString: "FFFFFFFFFFFFFFFF")
        XCTAssertNil(Int(hexData: testData))
    }

    func testUInt64FromHexConversion() {
        let testData = Data(hexString: "FFFFFFFFFFFFFFFF")
        XCTAssertEqual(18446744073709551615, UInt64(hexData: testData))
    }

    func testUInt64FromHexConversionOverflow() {
        let testData = Data(hexString: "FFFFFFFFFFFFFFFF01")
        XCTAssertNil(Int(hexData: testData))
    }
    
    func testToByteConversion() {
        XCTAssertEqual(15.byte, Data(hexString: "0F"))
        XCTAssertEqual(356.bytes2, Data(hexString: "0164"))
        XCTAssertEqual(3456988.bytes4, Data(hexString: "0034BFDC"))
        XCTAssertEqual(345698858557552.bytes8, Data(hexString: "00013A6949A9E070"))
    }

    // MARK: - bytes2

    func testBytes2Zero() {
        XCTAssertEqual(0.bytes2, Data([0x00, 0x00]))
    }

    func testBytes2MaxUInt16() {
        XCTAssertEqual(65535.bytes2, Data([0xFF, 0xFF]))
    }

    func testBytes2IsBigEndian() {
        // 256 = 0x0100
        XCTAssertEqual(256.bytes2, Data([0x01, 0x00]))
    }

    // MARK: - bytes4

    func testBytes4Zero() {
        XCTAssertEqual(0.bytes4, Data([0x00, 0x00, 0x00, 0x00]))
    }

    func testBytes4IsBigEndian() {
        // 65536 = 0x00010000
        XCTAssertEqual(65536.bytes4, Data([0x00, 0x01, 0x00, 0x00]))
    }

    // MARK: - bytes8

    func testBytes8Zero() {
        XCTAssertEqual(0.bytes8, Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))
    }

    func testBytes8Length() {
        XCTAssertEqual(1.bytes8.count, 8)
    }

    // MARK: - toBytes(count:)

    func testToBytesCount1() {
        // 255 = 0xFF
        XCTAssertEqual(255.toBytes(count: 1), Data([0xFF]))
    }

    func testToBytesCount2() {
        // 256 = 0x0100
        XCTAssertEqual(256.toBytes(count: 2), Data([0x01, 0x00]))
    }

    func testToBytesCount4() {
        XCTAssertEqual(1.toBytes(count: 4), Data([0x00, 0x00, 0x00, 0x01]))
    }

    // MARK: - UInt64.bytes8LE

    func testUInt64Bytes8LE() {
        let value: UInt64 = 1
        let data = value.bytes8LE
        XCTAssertEqual(data.count, 8)
        // Little-endian: least significant byte first
        XCTAssertEqual(data[0], 0x01)
        XCTAssertEqual(data[7], 0x00)
    }

    func testUInt64Bytes8LEZero() {
        let value: UInt64 = 0
        XCTAssertEqual(value.bytes8LE, Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))
    }

    // MARK: - UInt32.bytes4

    func testUInt32Bytes4() {
        let value: UInt32 = 256
        let data = value.bytes4
        XCTAssertEqual(data, Data([0x00, 0x00, 0x01, 0x00]))
    }

    func testUInt32Bytes4Max() {
        let value: UInt32 = UInt32.max
        XCTAssertEqual(value.bytes4, Data([0xFF, 0xFF, 0xFF, 0xFF]))
    }

    // MARK: - Int32 HexConvertible

    func testInt32HexConvertible() {
        let data = Data(hexString: "0001")
        XCTAssertEqual(Int32(hexData: data), 1)
    }

    func testInt32HexConvertibleLarger() {
        let data = Data(hexString: "FFFF")
        XCTAssertEqual(Int32(hexData: data), 65535)
    }
}
