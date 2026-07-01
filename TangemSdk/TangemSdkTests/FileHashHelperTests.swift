//
//  FileHashHelperTests.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemSdk

class FileHashHelperTests: XCTestCase {
    func testPrepareHashWithoutPrivateKey() throws {
        let cardId = "CB79000000018201"
        let fileData = Data("test file data".utf8)
        let fileCounter = 1

        let result = try FileHashHelper.prepareHash(for: cardId, fileData: fileData, fileCounter: fileCounter)

        // startingHash = cardId bytes + counter.bytes4 + fileData.count.bytes2
        let expectedStartHash = Data(hexString: cardId) + fileCounter.bytes4 + fileData.count.bytes2
        XCTAssertEqual(result.startingHash, expectedStartHash)

        // finalizingHash = cardId bytes + fileData + counter.bytes4
        let expectedFinalHash = Data(hexString: cardId) + fileData + fileCounter.bytes4
        XCTAssertEqual(result.finalizingHash, expectedFinalHash)

        // No private key → no signatures
        XCTAssertNil(result.startingSignature)
        XCTAssertNil(result.finalizingSignature)
    }

    func testPrepareHashWithPrivateKey() throws {
        let cardId = "CB79000000018201"
        let fileData = Data("test".utf8)
        let fileCounter = 5
        let privateKey = try CryptoUtils.generateRandomBytes(count: 32)

        let result = try FileHashHelper.prepareHash(
            for: cardId,
            fileData: fileData,
            fileCounter: fileCounter,
            privateKey: privateKey
        )

        XCTAssertNotNil(result.startingSignature)
        XCTAssertNotNil(result.finalizingSignature)
        XCTAssertNotNil(result.startingHash)
        XCTAssertNotNil(result.finalizingHash)
    }

    func testPrepareHashDeterministic() throws {
        let cardId = "CB79000000018201"
        let fileData = Data([0x01, 0x02, 0x03])
        let fileCounter = 0

        let result1 = try FileHashHelper.prepareHash(for: cardId, fileData: fileData, fileCounter: fileCounter)
        let result2 = try FileHashHelper.prepareHash(for: cardId, fileData: fileData, fileCounter: fileCounter)

        XCTAssertEqual(result1.startingHash, result2.startingHash)
        XCTAssertEqual(result1.finalizingHash, result2.finalizingHash)
    }
}
