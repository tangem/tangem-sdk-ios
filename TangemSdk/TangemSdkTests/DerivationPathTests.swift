//
//  DerivationPathTests.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class DerivationPathTests: XCTestCase {
    // MARK: - Parsing

    func testParseStandardPath() throws {
        let path = try DerivationPath(rawPath: "m/44'/0'/0'/0/0")

        XCTAssertEqual(path.nodes.count, 5)
        XCTAssertEqual(path.nodes[0], .hardened(44))
        XCTAssertEqual(path.nodes[1], .hardened(0))
        XCTAssertEqual(path.nodes[2], .hardened(0))
        XCTAssertEqual(path.nodes[3], .nonHardened(0))
        XCTAssertEqual(path.nodes[4], .nonHardened(0))
    }

    func testParseAlternativeHardenedSymbol() throws {
        let path = try DerivationPath(rawPath: "m/44\u{2019}/0\u{2019}/0\u{2019}")

        XCTAssertEqual(path.nodes.count, 3)
        XCTAssertTrue(path.nodes[0].isHardened)
        XCTAssertTrue(path.nodes[1].isHardened)
        XCTAssertTrue(path.nodes[2].isHardened)
    }

    func testParseCaseInsensitive() throws {
        let path = try DerivationPath(rawPath: "M/44'/0'")

        XCTAssertEqual(path.nodes.count, 2)
        XCTAssertEqual(path.nodes[0], .hardened(44))
    }

    func testParseMasterOnly() {
        XCTAssertThrowsError(try DerivationPath(rawPath: "m"))
    }

    func testParseEmptyString() {
        XCTAssertThrowsError(try DerivationPath(rawPath: ""))
    }

    func testParseInvalidMasterNode() {
        XCTAssertThrowsError(try DerivationPath(rawPath: "x/44'/0'"))
    }

    func testParseInvalidIndex() {
        XCTAssertThrowsError(try DerivationPath(rawPath: "m/abc/0"))
    }

    func testParseTrailingSeparator() {
        XCTAssertThrowsError(try DerivationPath(rawPath: "m/44'/"))
    }

    func testParseDoubleSeparator() {
        XCTAssertThrowsError(try DerivationPath(rawPath: "m/44'//0"))
    }

    // MARK: - Init from nodes

    func testInitFromNodes() {
        let path = DerivationPath(nodes: [.hardened(44), .hardened(60), .nonHardened(0)])

        XCTAssertEqual(path.rawPath, "m/44'/60'/0")
        XCTAssertEqual(path.nodes.count, 3)
    }

    func testEmptyNodes() {
        let path = DerivationPath(nodes: [])

        XCTAssertEqual(path.rawPath, "m")
        XCTAssertEqual(path.nodes.count, 0)
    }

    func testMasterPath() {
        let path = DerivationPath()

        XCTAssertEqual(path.rawPath, "m")
        XCTAssertEqual(path.nodes.count, 0)
    }

    // MARK: - extendedPath

    func testExtendedPath() {
        let base = DerivationPath(nodes: [.hardened(44)])
        let extended = base.extendedPath(with: .nonHardened(0))

        XCTAssertEqual(extended.nodes.count, 2)
        XCTAssertEqual(extended.rawPath, "m/44'/0")
    }

    // MARK: - Codable round-trip

    func testCodableRoundTrip() throws {
        let original = try DerivationPath(rawPath: "m/44'/60'/0'/0/0")
        let data = try JSONEncoder.tangemSdkEncoder.encode(original)
        let decoded = try JSONDecoder.tangemSdkDecoder.decode(DerivationPath.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.rawPath, "m/44'/60'/0'/0/0")
    }

    func testDecodeFromString() throws {
        let json = Data("\"m/44'/0'/0'\"".utf8)
        let decoded = try JSONDecoder.tangemSdkDecoder.decode(DerivationPath.self, from: json)

        XCTAssertEqual(decoded.nodes.count, 3)
        XCTAssertEqual(decoded.nodes[0], .hardened(44))
    }

    // MARK: - TLV round-trip

    func testTlvRoundTrip() throws {
        let original = DerivationPath(nodes: [.hardened(44), .hardened(0), .nonHardened(1)])
        let tlv = original.encodeTlv(with: .walletHDPath)
        let decoded = try DerivationPath(from: tlv.value)

        XCTAssertEqual(decoded, original)
    }

    func testTlvInvalidDataLength() {
        let invalidData = Data([0x00, 0x01, 0x02])
        XCTAssertThrowsError(try DerivationPath(from: invalidData))
    }

    // MARK: - Equatable / Hashable

    func testEquatable() throws {
        let path1 = try DerivationPath(rawPath: "m/44'/0'/0'")
        let path2 = DerivationPath(nodes: [.hardened(44), .hardened(0), .hardened(0)])

        XCTAssertEqual(path1, path2)
    }

    func testHashable() throws {
        let path1 = try DerivationPath(rawPath: "m/44'/0'")
        let path2 = try DerivationPath(rawPath: "m/44'/0'")
        let path3 = try DerivationPath(rawPath: "m/44'/1'")

        var set = Set<DerivationPath>()
        set.insert(path1)
        set.insert(path2)
        set.insert(path3)

        XCTAssertEqual(set.count, 2)
    }
}
