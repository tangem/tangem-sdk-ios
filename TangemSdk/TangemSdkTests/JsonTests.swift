//
//  TangemSdkTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 02/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemSdk

class JsonTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEllipticCurve() {
        let testJson = Data("{\"curve\":\"Secp256k1\"}".utf8)

        struct TestStruct: Codable {
            let curve: EllipticCurve
        }

        let decoded = try? JSONDecoder.tangemSdkDecoder.decode(TestStruct.self, from: testJson)
        XCTAssertNotNil(decoded)
    }
}
