//
//  DateExtensionTests.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemSdk

class DateExtensionTests: XCTestCase {
    func testToStringMediumStyle() throws {
        let components = DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2023, month: 1, day: 15
        )
        let date = try XCTUnwrap(Calendar.current.date(from: components))
        let result = date.toString(style: .medium, locale: Locale(identifier: "en_US"))
        XCTAssertEqual(result, "Jan 15, 2023")
    }

    func testToStringShortStyle() throws {
        let components = DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2023, month: 1, day: 15
        )
        let date = try XCTUnwrap(Calendar.current.date(from: components))
        let result = date.toString(style: .short, locale: Locale(identifier: "en_US"))
        XCTAssertEqual(result, "1/15/23")
    }

    func testToStringLongStyle() throws {
        let components = DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2023, month: 1, day: 15
        )
        let date = try XCTUnwrap(Calendar.current.date(from: components))
        let result = date.toString(style: .long, locale: Locale(identifier: "en_US"))
        XCTAssertEqual(result, "January 15, 2023")
    }
}
