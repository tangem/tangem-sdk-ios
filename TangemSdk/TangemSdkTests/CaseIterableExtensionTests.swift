//
//  CaseIterableExtensionTests.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemSdk

class CaseIterableExtensionTests: XCTestCase {
    private enum TestEnum: String, CaseIterable {
        case first
        case second
        case third
    }

    func testNextFromFirst() {
        XCTAssertEqual(TestEnum.first.next(), .second)
    }

    func testNextFromSecond() {
        XCTAssertEqual(TestEnum.second.next(), .third)
    }
}
