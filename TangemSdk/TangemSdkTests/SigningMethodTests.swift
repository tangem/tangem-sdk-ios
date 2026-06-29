//
//  SigningMethodTests.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class SigningMethodTests: XCTestCase {
    // MARK: - OptionSet basics

    func testContains() {
        let method: SigningMethod = [.signHash, .signRaw]
        XCTAssertTrue(method.contains(.signHash))
        XCTAssertTrue(method.contains(.signRaw))
        XCTAssertFalse(method.contains(.signPos))
    }

    func testSingleMethod() {
        let method = SigningMethod.signHash
        XCTAssertTrue(method.contains(.signHash))
        XCTAssertFalse(method.contains(.signRaw))
    }

    // MARK: - OptionSetCodable

    func testEncodeToStringArray() throws {
        let method: SigningMethod = [.signHash, .signRaw]
        let data = try JSONEncoder.tangemSdkEncoder.encode(method)
        let stringArray = try JSONDecoder().decode([String].self, from: data)

        XCTAssertTrue(stringArray.contains("SignHash"))
        XCTAssertTrue(stringArray.contains("SignRaw"))
        XCTAssertEqual(stringArray.count, 2)
    }

    func testDecodeFromStringArray() throws {
        let json = Data("[\"SignHash\", \"SignRaw\"]".utf8)
        let method = try JSONDecoder.tangemSdkDecoder.decode(SigningMethod.self, from: json)

        XCTAssertTrue(method.contains(.signHash))
        XCTAssertTrue(method.contains(.signRaw))
        XCTAssertFalse(method.contains(.signPos))
    }

    func testCodableRoundTrip() throws {
        let original: SigningMethod = [.signHash, .signHashSignedByIssuer]
        let data = try JSONEncoder.tangemSdkEncoder.encode(original)
        let decoded = try JSONDecoder.tangemSdkDecoder.decode(SigningMethod.self, from: data)

        XCTAssertTrue(decoded.contains(.signHash))
        XCTAssertTrue(decoded.contains(.signHashSignedByIssuer))
        XCTAssertFalse(decoded.contains(.signRaw))
    }
}
