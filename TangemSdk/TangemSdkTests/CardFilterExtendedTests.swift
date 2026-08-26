//
//  CardFilterExtendedTests.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class CardFilterExtendedTests: XCTestCase {
    // MARK: - ItemFilter

    func testItemFilterAllowContains() {
        let filter = CardFilter.ItemFilter.allow(["BATCH_A", "BATCH_B"])
        XCTAssertTrue(filter.isAllowed("BATCH_A"))
        XCTAssertTrue(filter.isAllowed("BATCH_B"))
        XCTAssertFalse(filter.isAllowed("BATCH_C"))
    }

    func testItemFilterDenyContains() {
        let filter = CardFilter.ItemFilter.deny(["BATCH_X"])
        XCTAssertFalse(filter.isAllowed("BATCH_X"))
        XCTAssertTrue(filter.isAllowed("BATCH_A"))
        XCTAssertTrue(filter.isAllowed("BATCH_B"))
    }

    func testItemFilterAllowEmpty() {
        let filter = CardFilter.ItemFilter.allow([])
        XCTAssertFalse(filter.isAllowed("anything"))
    }

    func testItemFilterDenyEmpty() {
        let filter = CardFilter.ItemFilter.deny([])
        XCTAssertTrue(filter.isAllowed("anything"))
    }

    // MARK: - CardIdFilter

    func testCardIdFilterAllowByIds() {
        let filter = CardFilter.CardIdFilter.allow(["CB79000000018201", "CB79000000018202"])
        XCTAssertTrue(filter.isAllowed("CB79000000018201"))
        XCTAssertTrue(filter.isAllowed("CB79000000018202"))
        XCTAssertFalse(filter.isAllowed("CB79000000018203"))
    }

    func testCardIdFilterAllowByRange() throws {
        let range = try XCTUnwrap(CardIdRange(start: "CB79000000018200", end: "CB79000000018210"))
        let filter = CardFilter.CardIdFilter.allow([], ranges: [range])

        XCTAssertTrue(filter.isAllowed("CB79000000018205"))
        XCTAssertFalse(filter.isAllowed("CB79000000019000"))
    }

    func testCardIdFilterAllowByIdsOrRange() throws {
        let range = try XCTUnwrap(CardIdRange(start: "AA00000000000000", end: "AA0000000000000F"))
        let filter = CardFilter.CardIdFilter.allow(["ZZZZ000000000001"], ranges: [range])

        XCTAssertTrue(filter.isAllowed("ZZZZ000000000001"))
        XCTAssertTrue(filter.isAllowed("AA00000000000005"))
        XCTAssertFalse(filter.isAllowed("BB00000000000000"))
    }

    func testCardIdFilterDenyByIds() {
        let filter = CardFilter.CardIdFilter.deny(["BLOCKED_CARD_ID"])
        XCTAssertFalse(filter.isAllowed("BLOCKED_CARD_ID"))
        XCTAssertTrue(filter.isAllowed("ALLOWED_CARD_ID"))
    }

    func testCardIdFilterDenyByRange() throws {
        let range = try XCTUnwrap(CardIdRange(start: "CB79000000018200", end: "CB79000000018210"))
        let filter = CardFilter.CardIdFilter.deny([], ranges: [range])

        XCTAssertFalse(filter.isAllowed("CB79000000018205"))
        XCTAssertTrue(filter.isAllowed("CB79000000019000"))
    }

    // MARK: - CardIdRange

    func testCardIdRangeInvalidHex() {
        XCTAssertNil(CardIdRange(start: "NOT_HEX", end: "ALSO_NOT_HEX"))
    }

    func testCardIdRangeContainsInvalidCardId() throws {
        let range = try XCTUnwrap(CardIdRange(start: "0000000000000000", end: "FFFFFFFFFFFFFFFF"))
        XCTAssertFalse(range.contains("NOT_A_HEX_VALUE"))
    }

    func testCardIdRangeBoundaryValues() throws {
        let range = try XCTUnwrap(CardIdRange(start: "0000000000000010", end: "0000000000000020"))
        XCTAssertTrue(range.contains("0000000000000010"))
        XCTAssertTrue(range.contains("0000000000000020"))
        XCTAssertTrue(range.contains("0000000000000015"))
        XCTAssertFalse(range.contains("000000000000000F"))
        XCTAssertFalse(range.contains("0000000000000021"))
    }

    // MARK: - Array<CardIdRange>.contains

    func testMultipleRangesContains() throws {
        let range1 = try XCTUnwrap(CardIdRange(start: "0000000000000000", end: "000000000000000F"))
        let range2 = try XCTUnwrap(CardIdRange(start: "0000000000000100", end: "00000000000001FF"))
        let ranges = [range1, range2]

        XCTAssertTrue(ranges.contains("0000000000000005"))
        XCTAssertTrue(ranges.contains("0000000000000150"))
        XCTAssertFalse(ranges.contains("0000000000000050"))
    }

    func testEmptyRangesContains() {
        let ranges: [CardIdRange] = []
        XCTAssertFalse(ranges.contains("0000000000000000"))
    }

    // MARK: - verifyCard via JSON fixture

    func testVerifyCardDefaultFilter() throws {
        let card = try decodeCardFromFixture()
        let filter = CardFilter.default

        XCTAssertNoThrow(try filter.verifyCard(card))
    }

    func testVerifyCardWrongType() throws {
        let card = try decodeCardFromFixture()
        var filter = CardFilter()
        filter.allowedCardTypes = [.sdk]

        XCTAssertThrowsError(try filter.verifyCard(card))
    }

    func testVerifyCardMaxFirmwareVersion() throws {
        let card = try decodeCardFromFixture()
        var filter = CardFilter()
        filter.maxFirmwareVersion = FirmwareVersion(major: 3, minor: 0)

        XCTAssertThrowsError(try filter.verifyCard(card))
    }

    func testVerifyCardMaxFirmwareVersionAllowed() throws {
        let card = try decodeCardFromFixture()
        var filter = CardFilter()
        filter.maxFirmwareVersion = FirmwareVersion(major: 5, minor: 0)

        XCTAssertNoThrow(try filter.verifyCard(card))
    }

    func testVerifyCardBatchIdFilterAllow() throws {
        let card = try decodeCardFromFixture()
        var filter = CardFilter()
        filter.batchIdFilter = .allow(["CB79"])

        XCTAssertNoThrow(try filter.verifyCard(card))
    }

    func testVerifyCardBatchIdFilterDeny() throws {
        let card = try decodeCardFromFixture()
        var filter = CardFilter()
        filter.batchIdFilter = .deny(["CB79"])

        XCTAssertThrowsError(try filter.verifyCard(card))
    }

    func testVerifyCardIssuerFilterAllow() throws {
        let card = try decodeCardFromFixture()
        var filter = CardFilter()
        filter.issuerFilter = .allow(["TANGEM AG"])

        XCTAssertNoThrow(try filter.verifyCard(card))
    }

    func testVerifyCardIssuerFilterDeny() throws {
        let card = try decodeCardFromFixture()
        var filter = CardFilter()
        filter.issuerFilter = .deny(["TANGEM AG"])

        XCTAssertThrowsError(try filter.verifyCard(card))
    }

    func testVerifyCardCardIdFilterAllow() throws {
        let card = try decodeCardFromFixture()
        var filter = CardFilter()
        filter.cardIdFilter = .allow(["CB79000000018201"])

        XCTAssertNoThrow(try filter.verifyCard(card))
    }

    func testVerifyCardCardIdFilterDeny() throws {
        let card = try decodeCardFromFixture()
        var filter = CardFilter()
        filter.cardIdFilter = .deny(["CB79000000018201"])

        XCTAssertThrowsError(try filter.verifyCard(card))
    }

    // MARK: - Helpers

    private func decodeCardFromFixture() throws -> Card {
        let data = try Bundle.readFileAsData(name: "Card", in: .root)
        return try JSONDecoder.tangemSdkDecoder.decode(Card.self, from: data)
    }
}
