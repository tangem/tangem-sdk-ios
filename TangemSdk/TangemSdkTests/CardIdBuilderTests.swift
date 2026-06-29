//
//  CardIdBuilderTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 19.03.2026.
//

import Foundation
import XCTest
@testable import TangemSdk

class CardIdBuilderTests: XCTestCase {
    // MARK: - Simple path tests

    func testCreateCardId_4CharSeries_StartNumber0() {
        XCTAssertEqual(CardIdBuilder.createCardId(series: "AAAA", startNumber: 0), "AAAA000000000000")
    }

    func testCreateCardId_2CharSeries_StartNumber0() {
        XCTAssertEqual(CardIdBuilder.createCardId(series: "AB", startNumber: 0), "AB00000000000009")
    }

    func testCreateCardId_4CharSeries_StartNumber100() {
        XCTAssertEqual(CardIdBuilder.createCardId(series: "AAAA", startNumber: 100), "AAAA000000001008")
    }

    func testCreateCardId_WithCardNumber() {
        XCTAssertEqual(CardIdBuilder.createCardId(series: "AAAA", startNumber: 100, cardNumber: 5), "AAAA000000001057")
    }

    func testCreateCardId_1CharSeries_StartNumber0() {
        XCTAssertEqual(CardIdBuilder.createCardId(series: "A", startNumber: 0), "A000000000000000")
    }

    func testCreateCardId_8CharSeries_StartNumber5() {
        XCTAssertEqual(CardIdBuilder.createCardId(series: "DD000000", startNumber: 5), "DD00000000000050")
    }

    func testCreateCardId_TooLongSeries_ReturnsNil() {
        XCTAssertNil(CardIdBuilder.createCardId(series: "AAAAAAAAAAAAAAA", startNumber: 0))
    }

    func testCreateCardId_EmptySeries_ReturnsNil() {
        XCTAssertNil(CardIdBuilder.createCardId(series: "", startNumber: 0))
    }

    func testCreateCardId_InvalidSeriesChars_ReturnsNil() {
        XCTAssertNil(CardIdBuilder.createCardId(series: "ZZZZ", startNumber: 0))
    }

    func testCreateCardId_NegativeStartNumber_ReturnsNil() {
        XCTAssertNil(CardIdBuilder.createCardId(series: "AAAA", startNumber: -1))
    }

    // MARK: - NumberFormat tests

    func testNumberFormat_AllN_4CharSeries() {
        XCTAssertEqual(CardIdBuilder.createCardId(series: "AAAA", startNumber: 42, numberFormat: "NNNNNNNNNNN"), "AAAA000000000422")
    }

    func testNumberFormat_AllN_2CharSeries() {
        XCTAssertEqual(CardIdBuilder.createCardId(series: "AB", startNumber: 0, numberFormat: "NNNNNNNNNNNNN"), "AB00000000000009")
    }

    func testNumberFormat_WithCardNumber() {
        XCTAssertEqual(CardIdBuilder.createCardId(series: "AAAA", startNumber: 100, cardNumber: 5, numberFormat: "NNNNNNNNNNN"), "AAAA000000001057")
    }

    func testNumberFormat_AllN_8CharSeries() {
        XCTAssertEqual(CardIdBuilder.createCardId(series: "DD000000", startNumber: 0, numberFormat: "NNNNNNN"), "DD00000000000001")
    }

    func testNumberFormat_AllN_8CharSeries_WithCardNumber() {
        XCTAssertEqual(CardIdBuilder.createCardId(series: "DD000000", startNumber: 100, cardNumber: 5, numberFormat: "NNNNNNN"), "DD00000000001058")
    }

    func testNumberFormat_InvalidLength_ReturnsNil() {
        XCTAssertNil(CardIdBuilder.createCardId(series: "AAAA", startNumber: 0, numberFormat: "NNNNN"))
    }

    func testNumberFormat_3CharSeries() {
        XCTAssertEqual(CardIdBuilder.createCardId(series: "AAA", startNumber: 0, numberFormat: "NNNNNNNNNNNN"), "AAA0000000000000")
    }

    func testNumberFormat_InvalidSeriesChars_ReturnsNil() {
        XCTAssertNil(CardIdBuilder.createCardId(series: "ZZZZ", startNumber: 0, numberFormat: "NNNNNNNNNNN"))
    }

    func testNumberFormat_InvalidChars_ReturnsNil() {
        XCTAssertNil(CardIdBuilder.createCardId(series: "AAAA", startNumber: 0, numberFormat: "NNNNNNN.NNN"))
    }

    // MARK: - No Luhn tests

    func testNoLuhn_SimplePath_8CharSeries() {
        XCTAssertEqual(CardIdBuilder.createCardId(series: "DD000000", startNumber: 5, useLuhn: false), "DD00000000000005")
    }

    func testNoLuhn_NumberFormat_8CharSeries() {
        XCTAssertEqual(CardIdBuilder.createCardId(series: "DD000000", startNumber: 0, numberFormat: "NNNNNNNN", useLuhn: false), "DD00000000000000")
    }

    func testNoLuhn_NumberFormat_WithCardNumber() {
        XCTAssertEqual(CardIdBuilder.createCardId(series: "DD000000", startNumber: 100, cardNumber: 5, numberFormat: "NNNNNNNN", useLuhn: false), "DD00000000000105")
    }

    func testNoLuhn_NumberFormat_InvalidLength_ReturnsNil() {
        XCTAssertNil(CardIdBuilder.createCardId(series: "DD000000", startNumber: 0, numberFormat: "NNNNNNN", useLuhn: false))
    }
}
