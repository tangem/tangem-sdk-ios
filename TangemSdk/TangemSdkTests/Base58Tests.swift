//
//  Base58Tests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 13.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

@available(iOS 13.0, *)
class Base58Tests: XCTestCase {
    func testRoundTrip() {
        let data = Data(repeating: UInt8(1), count: 32)
        XCTAssertEqual(data.base58CheckEncodedString.base58CheckDecodedData, data)
        XCTAssertEqual(data.base58EncodedString.base58DecodedData, data)

        let array = [UInt8](repeating: UInt8(1), count: 32)
        XCTAssertEqual(array.base58CheckEncodedString.base58CheckDecodedBytes, array)
        XCTAssertEqual(array.base58EncodedString.base58DecodedBytes, array)
    }
}
