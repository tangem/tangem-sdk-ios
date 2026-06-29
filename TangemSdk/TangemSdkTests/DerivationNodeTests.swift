//
//  DerivationNodeTests.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class DerivationNodeTests: XCTestCase {
    // MARK: - pathDescription

    func testHardenedPathDescription() {
        let node = DerivationNode.hardened(44)
        XCTAssertEqual(node.pathDescription, "44'")
    }

    func testNonHardenedPathDescription() {
        let node = DerivationNode.nonHardened(0)
        XCTAssertEqual(node.pathDescription, "0")
    }

    // MARK: - index

    func testHardenedIndex() {
        let node = DerivationNode.hardened(44)
        XCTAssertEqual(node.index, 44 + BIP32.Constants.hardenedOffset)
    }

    func testNonHardenedIndex() {
        let node = DerivationNode.nonHardened(5)
        XCTAssertEqual(node.index, 5)
    }

    // MARK: - isHardened

    func testIsHardened() {
        XCTAssertTrue(DerivationNode.hardened(0).isHardened)
        XCTAssertFalse(DerivationNode.nonHardened(0).isHardened)
    }

    // MARK: - rawIndex

    func testRawIndex() {
        XCTAssertEqual(DerivationNode.hardened(44).rawIndex, 44)
        XCTAssertEqual(DerivationNode.nonHardened(7).rawIndex, 7)
    }

    // MARK: - withRawIndex

    func testWithRawIndex() {
        let hardened = DerivationNode.hardened(0).withRawIndex(99)
        XCTAssertEqual(hardened, DerivationNode.hardened(99))

        let nonHardened = DerivationNode.nonHardened(0).withRawIndex(42)
        XCTAssertEqual(nonHardened, DerivationNode.nonHardened(42))
    }

    // MARK: - fromIndex

    func testFromIndexNonHardened() {
        let node = DerivationNode.fromIndex(5)
        XCTAssertEqual(node, DerivationNode.nonHardened(5))
    }

    func testFromIndexHardened() {
        let hardenedIndex = 44 + BIP32.Constants.hardenedOffset
        let node = DerivationNode.fromIndex(hardenedIndex)
        XCTAssertEqual(node, DerivationNode.hardened(44))
    }

    func testFromIndexBoundary() {
        let node = DerivationNode.fromIndex(BIP32.Constants.hardenedOffset - 1)
        XCTAssertEqual(node, DerivationNode.nonHardened(BIP32.Constants.hardenedOffset - 1))

        let hardenedNode = DerivationNode.fromIndex(BIP32.Constants.hardenedOffset)
        XCTAssertEqual(hardenedNode, DerivationNode.hardened(0))
    }

    // MARK: - Serialization round-trip

    func testSerializeDeserializeHardened() {
        let original = DerivationNode.hardened(44)
        let data = original.serialize()
        let deserialized = DerivationNode.deserialize(from: data)
        XCTAssertEqual(deserialized, original)
    }

    func testSerializeDeserializeNonHardened() {
        let original = DerivationNode.nonHardened(0)
        let data = original.serialize()
        let deserialized = DerivationNode.deserialize(from: data)
        XCTAssertEqual(deserialized, original)
    }

    func testDeserializeInvalidData() {
        let emptyData = Data()
        XCTAssertNil(DerivationNode.deserialize(from: emptyData))
    }

    func testSerializeProduces4Bytes() {
        let data = DerivationNode.hardened(0).serialize()
        XCTAssertEqual(data.count, 4)
    }

    // MARK: - Equatable

    func testEquatable() {
        XCTAssertEqual(DerivationNode.hardened(44), DerivationNode.hardened(44))
        XCTAssertNotEqual(DerivationNode.hardened(44), DerivationNode.nonHardened(44))
        XCTAssertNotEqual(DerivationNode.hardened(44), DerivationNode.hardened(45))
    }
}
