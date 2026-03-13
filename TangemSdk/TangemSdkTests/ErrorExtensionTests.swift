//
//  ErrorExtensionTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 12.03.2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemSdk

class ErrorExtensionTests: XCTestCase {
    func testTangemSdkErrorPassesThrough() {
        let error: Error = TangemSdkError.invalidParams
        let converted = error.toTangemSdkError()
        XCTAssertEqual(converted.code, TangemSdkError.invalidParams.code)
    }

    func testGenericErrorWrappedAsUnderlying() {
        let error: Error = NSError(domain: "test", code: 42)
        let converted = error.toTangemSdkError()
        if case .underlying(error: let underlying) = converted {
            XCTAssertEqual((underlying as NSError).code, 42)
        } else {
            XCTFail("Expected .underlying, got \(converted)")
        }
    }
}
