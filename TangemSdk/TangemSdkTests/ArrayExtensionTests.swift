//
//  ArrayExtensionTests.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemSdk

class ArrayExtensionTests: XCTestCase {
    // MARK: - chunked(into:)

    func testChunkedEvenSplit() {
        let array = [1, 2, 3, 4, 5, 6]
        let chunks = array.chunked(into: 2)
        XCTAssertEqual(chunks, [[1, 2], [3, 4], [5, 6]])
    }

    func testChunkedUnevenSplit() {
        let array = [1, 2, 3, 4, 5]
        let chunks = array.chunked(into: 2)
        XCTAssertEqual(chunks, [[1, 2], [3, 4], [5]])
    }

    func testChunkedSizeGreaterThanCount() {
        let array = [1, 2, 3]
        let chunks = array.chunked(into: 10)
        XCTAssertEqual(chunks, [[1, 2, 3]])
    }

    func testChunkedSizeEqualToCount() {
        let array = [1, 2, 3]
        let chunks = array.chunked(into: 3)
        XCTAssertEqual(chunks, [[1, 2, 3]])
    }

    func testChunkedSizeOne() {
        let array = [1, 2, 3]
        let chunks = array.chunked(into: 1)
        XCTAssertEqual(chunks, [[1], [2], [3]])
    }

    func testChunkedEmptyArray() {
        let array: [Int] = []
        let chunks = array.chunked(into: 3)
        XCTAssertTrue(chunks.isEmpty)
    }

    // MARK: - reversedChunked(into:)

    func testReversedChunkedEvenSplit() {
        let array = [1, 2, 3, 4, 5, 6]
        let chunks = array.reversedChunked(into: 2)
        XCTAssertEqual(chunks, [[5, 6], [3, 4], [1, 2]])
    }

    func testReversedChunkedUnevenSplit() {
        let array = [1, 2, 3, 4, 5]
        let chunks = array.reversedChunked(into: 2)
        XCTAssertEqual(chunks, [[4, 5], [2, 3], [1]])
    }

    func testReversedChunkedEmptyArray() {
        let array: [Int] = []
        let chunks = array.reversedChunked(into: 3)
        XCTAssertTrue(chunks.isEmpty)
    }

    func testReversedChunkedSizeGreaterThanCount() {
        let array = [1, 2, 3]
        let chunks = array.reversedChunked(into: 10)
        XCTAssertEqual(chunks, [[1, 2, 3]])
    }
}
