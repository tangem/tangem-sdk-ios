//
//  EntropyLengthTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 16/03/2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class EntropyLengthTests: XCTestCase {

    func testWordCount() {
        XCTAssertEqual(EntropyLength.bits128.wordCount, 12)
        XCTAssertEqual(EntropyLength.bits160.wordCount, 15)
        XCTAssertEqual(EntropyLength.bits192.wordCount, 18)
        XCTAssertEqual(EntropyLength.bits224.wordCount, 21)
        XCTAssertEqual(EntropyLength.bits256.wordCount, 24)
    }

    func testChecksumBitsCount() {
        XCTAssertEqual(EntropyLength.bits128.cheksumBitsCount, 4)
        XCTAssertEqual(EntropyLength.bits160.cheksumBitsCount, 5)
        XCTAssertEqual(EntropyLength.bits192.cheksumBitsCount, 6)
        XCTAssertEqual(EntropyLength.bits224.cheksumBitsCount, 7)
        XCTAssertEqual(EntropyLength.bits256.cheksumBitsCount, 8)
    }

    func testRawValues() {
        XCTAssertEqual(EntropyLength.bits128.rawValue, 128)
        XCTAssertEqual(EntropyLength.bits160.rawValue, 160)
        XCTAssertEqual(EntropyLength.bits192.rawValue, 192)
        XCTAssertEqual(EntropyLength.bits224.rawValue, 224)
        XCTAssertEqual(EntropyLength.bits256.rawValue, 256)
    }

    func testAllCases() {
        XCTAssertEqual(EntropyLength.allCases.count, 5)
    }
}
