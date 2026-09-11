//
//  CodableExtensionTests.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemSdk

class CodableExtensionTests: XCTestCase {
    // MARK: - Test model

    private struct TestModel: Codable, Equatable {
        let someField: String
        let dataValue: Data
        let dateValue: Date
    }

    // MARK: - Encoder/Decoder round-trip

    func testRoundTripWithTangemSdkCoder() throws {
        let components = DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2023, month: 6, day: 15
        )
        let date = try XCTUnwrap(Calendar(identifier: .gregorian).date(from: components))
        let model = TestModel(someField: "hello", dataValue: Data(hexString: "DEADBEEF"), dateValue: date)

        let encoded = try JSONEncoder.tangemSdkEncoder.encode(model)
        let decoded = try JSONDecoder.tangemSdkDecoder.decode(TestModel.self, from: encoded)

        XCTAssertEqual(decoded.someField, model.someField)
        XCTAssertEqual(decoded.dataValue, model.dataValue)
        // Date comparison with calendar day precision
        let calendar = Calendar(identifier: .gregorian)
        XCTAssertEqual(calendar.component(.year, from: decoded.dateValue), 2023)
        XCTAssertEqual(calendar.component(.month, from: decoded.dateValue), 6)
        XCTAssertEqual(calendar.component(.day, from: decoded.dateValue), 15)
    }

    func testDataEncodedAsHex() throws {
        let model = TestModel(
            someField: "test",
            dataValue: Data(hexString: "AABB"),
            dateValue: Date()
        )

        let encoded = try JSONEncoder.tangemSdkEncoder.encode(model)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        let dataString = json["dataValue"] as? String
        XCTAssertEqual(dataString, "AABB")
    }

    func testSnakeCaseDecoding() throws {
        let json = Data("""
        {"some_field": "value", "data_value": "FF", "date_value": "2023-01-01"}
        """.utf8)

        let decoded = try JSONDecoder.tangemSdkDecoder.decode(TestModel.self, from: json)
        XCTAssertEqual(decoded.someField, "value")
        XCTAssertEqual(decoded.dataValue, Data(hexString: "FF"))
    }

    func testTestEncoderHasSortedKeys() throws {
        let model = TestModel(
            someField: "a",
            dataValue: Data(hexString: "BB"),
            dateValue: Date()
        )

        let encoded = try JSONEncoder.tangemSdkTestEncoder.encode(model)
        let jsonString = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        // sortedKeys should put "dataValue" before "dateValue" before "someField"
        let dataRange = try XCTUnwrap(jsonString.range(of: "dataValue"))
        let someRange = try XCTUnwrap(jsonString.range(of: "someField"))
        XCTAssertTrue(dataRange.lowerBound < someRange.lowerBound)
    }
}
