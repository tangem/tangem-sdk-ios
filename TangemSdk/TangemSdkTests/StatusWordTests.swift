//
//  StatusWordTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 12.03.2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemSdk

class StatusWordTests: XCTestCase {
    private func assertMapsTo(_ statusWord: StatusWord, _ expectedError: TangemSdkError, file: StaticString = #filePath, line: UInt = #line) {
        let result = statusWord.toTangemSdkError()
        XCTAssertNotNil(result, "Expected non-nil error for \(statusWord)", file: file, line: line)
        XCTAssertEqual(result?.code, expectedError.code, "Expected \(expectedError) but got \(String(describing: result))", file: file, line: line)
    }

    func testProcessCompletedReturnsNil() {
        XCTAssertNil(StatusWord.processCompleted.toTangemSdkError())
    }

    func testPinChangedReturnsNil() {
        XCTAssertNil(StatusWord.pin1Changed.toTangemSdkError())
        XCTAssertNil(StatusWord.pin2Changed.toTangemSdkError())
        XCTAssertNil(StatusWord.pin3Changed.toTangemSdkError())
    }

    func testNeedEncryption() {
        assertMapsTo(.needEcryption, .needEncryption)
    }

    func testInvalidParams() {
        assertMapsTo(.invalidParams, .invalidParams)
    }

    func testErrorProcessingCommand() {
        assertMapsTo(.errorProcessingCommand, .errorProcessingCommand)
    }

    func testInvalidState() {
        assertMapsTo(.invalidState, .invalidState)
    }

    func testInsNotSupported() {
        assertMapsTo(.insNotSupported, .insNotSupported)
    }

    func testFileNotFound() {
        assertMapsTo(.fileNotFound, .fileNotFound)
    }

    func testWalletNotFound() {
        assertMapsTo(.walletNotFound, .walletNotFound)
    }

    func testInvalidAccessCode() {
        assertMapsTo(.invalidAccessCode, .accessCodeRequired)
    }

    func testInvalidPasscode() {
        assertMapsTo(.invalidPascode, .passcodeRequired)
    }

    func testWalletAlreadyExists() {
        assertMapsTo(.walletAlreadyExists, .walletAlreadyCreated)
    }

    func testAccessDenied() {
        assertMapsTo(.accessDenied, .accessDenied)
    }

    func testUnknownReturnsNil() {
        XCTAssertNil(StatusWord.unknown.toTangemSdkError())
    }

    func testNeedPauseReturnsNil() {
        XCTAssertNil(StatusWord.needPause.toTangemSdkError())
    }

    func testInitFromRawValue() {
        XCTAssertEqual(StatusWord(rawValue: 0x9000), .processCompleted)
        XCTAssertEqual(StatusWord(rawValue: 0x6982), .needEcryption)
        XCTAssertNil(StatusWord(rawValue: 0xFFFF))
    }
}
