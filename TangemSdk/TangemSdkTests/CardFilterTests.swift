//
//  CardFilterTests.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 10/03/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class CardFilterTests: XCTestCase {

    func testCardIDRange() throws {
        let range = try XCTUnwrap(CardIdRange(start: "0000000000000000", end: "FFFFFFFFFFFFFFFF"))

        XCTAssertTrue(range.contains("0000000000000000"))
        XCTAssertTrue(range.contains("CB79000000018201"))
        XCTAssertTrue(range.contains("FFFFFFFFFFFFFFFF"))
    }

    func testCardIDRange2() throws {
        let range = try XCTUnwrap(CardIdRange(start: "CB79000000018201", end: "CB79000000019000"))

        XCTAssertTrue(range.contains("CB79000000018204"))
        XCTAssertFalse(range.contains("0000000000000000"))
        XCTAssertFalse(range.contains("FFFFFFFFFFFFFFFF"))
    }

    func testCardIDRangeBad() throws {
        XCTAssertNil(CardIdRange(start: "CB79000000018201", end: "CB79000000018200"))
        XCTAssertNil(CardIdRange(start: "CB79000000018201", end: "CB79000000018201"))
    }
}
