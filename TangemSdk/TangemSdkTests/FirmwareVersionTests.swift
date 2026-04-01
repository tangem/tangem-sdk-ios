//
//  FirmwareVersionTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 16/03/2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class FirmwareVersionTests: XCTestCase {
    // MARK: - Parsing

    func testParseRelease() {
        let fw = FirmwareVersion(stringValue: "4.12r")
        XCTAssertEqual(fw.major, 4)
        XCTAssertEqual(fw.minor, 12)
        XCTAssertEqual(fw.patch, 0)
        XCTAssertEqual(fw.type, .release)
    }

    func testParseReleaseImplicit() {
        let fw = FirmwareVersion(stringValue: "4.12")
        XCTAssertEqual(fw.major, 4)
        XCTAssertEqual(fw.minor, 12)
        XCTAssertEqual(fw.type, .release)
    }

    func testParseSDK() {
        let fw = FirmwareVersion(stringValue: "6.33d SDK")
        XCTAssertEqual(fw.major, 6)
        XCTAssertEqual(fw.minor, 33)
        XCTAssertEqual(fw.type, .sdk)
    }

    func testParseSpecial() {
        let fw = FirmwareVersion(stringValue: "4.45 mfi")
        XCTAssertEqual(fw.major, 4)
        XCTAssertEqual(fw.minor, 45)
        XCTAssertEqual(fw.type, .special)
    }

    func testParseWithPatch() {
        let fw = FirmwareVersion(stringValue: "8.48.1r")
        XCTAssertEqual(fw.major, 8)
        XCTAssertEqual(fw.minor, 48)
        XCTAssertEqual(fw.patch, 1)
        XCTAssertEqual(fw.type, .release)
    }

    // MARK: - Init with components

    func testInitWithComponents() {
        let fw = FirmwareVersion(major: 4, minor: 39, patch: 0, type: .release)
        XCTAssertEqual(fw.major, 4)
        XCTAssertEqual(fw.minor, 39)
        XCTAssertEqual(fw.stringValue, "4.39r")
    }

    func testInitWithPatch() {
        let fw = FirmwareVersion(major: 8, minor: 48, patch: 2, type: .sdk)
        XCTAssertEqual(fw.stringValue, "8.48.2d SDK")
    }

    func testInitWithZeroPatchOmitted() {
        let fw = FirmwareVersion(major: 4, minor: 12, patch: 0, type: .release)
        XCTAssertEqual(fw.stringValue, "4.12r")
    }

    // MARK: - Comparison

    func testLessThan() {
        let v4_12 = FirmwareVersion(major: 4, minor: 12)
        let v4_39 = FirmwareVersion(major: 4, minor: 39)
        let v6_21 = FirmwareVersion(major: 6, minor: 21)

        XCTAssertTrue(v4_12 < v4_39)
        XCTAssertTrue(v4_39 < v6_21)
        XCTAssertFalse(v6_21 < v4_39)
    }

    func testEqual() {
        let a = FirmwareVersion(major: 4, minor: 39)
        let b = FirmwareVersion(major: 4, minor: 39)
        XCTAssertEqual(a, b)
    }

    func testEqualIgnoresType() {
        let release = FirmwareVersion(major: 4, minor: 39, patch: 0, type: .release)
        let sdk = FirmwareVersion(major: 4, minor: 39, patch: 0, type: .sdk)
        XCTAssertEqual(release, sdk)
    }

    func testGreaterThanOrEqual() {
        let v4_39 = FirmwareVersion(major: 4, minor: 39)
        let v4_39_dup = FirmwareVersion(major: 4, minor: 39)
        let v4_12 = FirmwareVersion(major: 4, minor: 12)

        XCTAssertTrue(v4_39 >= v4_39_dup)
        XCTAssertTrue(v4_39 >= v4_12)
        XCTAssertFalse(v4_12 >= v4_39)
    }

    func testPatchComparison() {
        let v8_48_0 = FirmwareVersion(major: 8, minor: 48, patch: 0)
        let v8_48_1 = FirmwareVersion(major: 8, minor: 48, patch: 1)

        XCTAssertTrue(v8_48_0 < v8_48_1)
        XCTAssertTrue(v8_48_1 >= v8_48_0)
        XCTAssertFalse(v8_48_0 == v8_48_1)
    }

    // MARK: - Optional comparison

    func testOptionalLessThan() {
        let nilVersion: FirmwareVersion? = nil
        let v4_39 = FirmwareVersion(major: 4, minor: 39)

        XCTAssertFalse(nilVersion < v4_39)
    }

    func testOptionalGreaterThanOrEqual() {
        let nilVersion: FirmwareVersion? = nil
        let v4_39 = FirmwareVersion(major: 4, minor: 39)

        XCTAssertFalse(nilVersion >= v4_39)
    }

    // MARK: - doubleValue

    func testDoubleValue() {
        let fw = FirmwareVersion(major: 4, minor: 39)
        XCTAssertEqual(fw.doubleValue, 4.39, accuracy: 0.001)
    }

    // MARK: - FirmwareType

    func testFirmwareTypeForEmptyString() {
        XCTAssertEqual(FirmwareVersion.FirmwareType.type(for: ""), .release)
    }

    func testFirmwareTypeForWhitespace() {
        XCTAssertEqual(FirmwareVersion.FirmwareType.type(for: "  "), .release)
    }

    func testFirmwareTypeForSDK() {
        XCTAssertEqual(FirmwareVersion.FirmwareType.type(for: "d SDK"), .sdk)
    }

    func testFirmwareTypeForRelease() {
        XCTAssertEqual(FirmwareVersion.FirmwareType.type(for: "r"), .release)
    }

    func testFirmwareTypeForUnknown() {
        XCTAssertEqual(FirmwareVersion.FirmwareType.type(for: "mfi"), .special)
    }

    // MARK: - Codable round-trip

    func testCodableRoundTrip() throws {
        let original = FirmwareVersion(major: 4, minor: 39, patch: 0, type: .release)
        let data = try JSONEncoder.tangemSdkEncoder.encode(original)
        let decoded = try JSONDecoder.tangemSdkDecoder.decode(FirmwareVersion.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.type, .release)
    }

    // MARK: - Constants

    func testKnownVersionConstants() {
        XCTAssertTrue(FirmwareVersion.multiwalletAvailable < FirmwareVersion.hdWalletAvailable)
        XCTAssertEqual(FirmwareVersion.hdWalletAvailable, FirmwareVersion.backupAvailable)
        XCTAssertTrue(FirmwareVersion.keysImportAvailable < FirmwareVersion.v8)
    }
}
