//
//  Ripemd160Tests.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemSdk

class Ripemd160Tests: XCTestCase {
    /// Standard RIPEMD-160 test vectors from the spec
    func testEmptyString() {
        let data = Data()
        var md = RIPEMD160()
        md.update(data: data)
        let hash = md.finalize()
        XCTAssertEqual(hash.hexString, "9C1185A5C5E9FC54612808977EE8F548B2258D31")
    }

    func testSingleCharA() {
        let data = Data("a".utf8)
        var md = RIPEMD160()
        md.update(data: data)
        let hash = md.finalize()
        XCTAssertEqual(hash.hexString, "0BDC9D2D256B3EE9DAAE347BE6F4DC835A467FFE")
    }

    func testABC() {
        let data = Data("abc".utf8)
        var md = RIPEMD160()
        md.update(data: data)
        let hash = md.finalize()
        XCTAssertEqual(hash.hexString, "8EB208F7E05D987A9B044A8E98C6B087F15A0BFC")
    }

    func testMessageDigest() {
        let data = Data("message digest".utf8)
        var md = RIPEMD160()
        md.update(data: data)
        let hash = md.finalize()
        XCTAssertEqual(hash.hexString, "5D0689EF49D2FAE572B881B123A85FFA21595F36")
    }

    func testAlphabet() {
        let data = Data("abcdefghijklmnopqrstuvwxyz".utf8)
        var md = RIPEMD160()
        md.update(data: data)
        let hash = md.finalize()
        XCTAssertEqual(hash.hexString, "F71C27109C692C1B56BBDCEB5B9D2865B3708DBC")
    }

    /// Test Data extension convenience properties
    func testDataRipemd160() {
        let data = Data("abc".utf8)
        XCTAssertEqual(data.ripemd160.hexString, "8EB208F7E05D987A9B044A8E98C6B087F15A0BFC")
    }

    func testDataSha256Ripemd160() {
        // SHA256("abc") then RIPEMD160
        let data = Data("abc".utf8)
        let sha256 = data.getSHA256()
        var md = RIPEMD160()
        md.update(data: sha256)
        let expected = md.finalize()
        XCTAssertEqual(data.sha256Ripemd160, expected)
    }
}
