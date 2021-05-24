//
//  JSONRPCTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 21.05.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class JSONRPCTests: XCTestCase {
    func testJsonRPCRequestParse() {
        let json = "{\"jsonrpc\": \"2.0\", \"method\": \"subtract\", \"params\": {\"subtrahend\": 23, \"minuend\": 42}, \"id\": 3}"
        
        let request = try? JSONRPCRequest(jsonString: json)
        XCTAssertNotNil(request)
        XCTAssertEqual(request!.method, "subtract")
        XCTAssertEqual(request!.params["subtrahend"] as! Int, Int(23))
    }
    func testDecodeSingleHex() {
        var dict: [String: Any] = .init()
        dict["pubKey"] = "AABBCCDDEEFF"
        let data: Data = try! dict.value(for: "pubKey")
        XCTAssert(data == Data(hexString: "AABBCCDDEEFF"))
    }
    
    func testDecodeMultipleHex() {
        var dict: [String: Any] = .init()
        dict["hashes"] = ["AABBCCDDEEFF", "AABBCCDDEEFFGG"]
        let data: [Data] = try! dict.value(for: "hashes")
        XCTAssert(data[0] == Data(hexString: "AABBCCDDEEFF"))
        XCTAssert(data[1] == Data(hexString: "AABBCCDDEEFFGG"))
    }
    
    func testMakeScan() {
        let json = "{\"jsonrpc\": \"2.0\", \"method\": \"scan_task\", \"params\": {\"cardVerification\": false}, \"id\": 1}"
        let request = try? JSONRPCRequest(jsonString: json)
        XCTAssertNotNil(request)
        let task = try? JSONRPCConverter.shared.convert(request: request!)
        XCTAssertNotNil(task)
    }
    
    func testMakeSign() {
        let json = "{\"jsonrpc\": \"2.0\", \"method\": \"sign_command\", \"params\": {\"walletIndex\": \"AABBCCDDEEFFGGHHKKLLMMNN\", \"hashes\": [\"AABBCCDDEEFF\", \"AABBCCDDEEFFGG\"]}, \"id\": 1}"
        let request = try? JSONRPCRequest(jsonString: json)
        XCTAssertNotNil(request)
        let task = try? JSONRPCConverter.shared.convert(request: request!)
        XCTAssertNotNil(task)
    }
    
    func testMethodNotFound() {
        let json = "{\"jsonrpc\": \"2.0\", \"method\": \"sign_task\", \"params\": {\"walletIndex\": \"AABBCCDDEEFFGGHHKKLLMMNN\", \"hashes\": [\"AABBCCDDEEFF\", \"AABBCCDDEEFFGG\"]}, \"id\": 1}"
        let request = try? JSONRPCRequest(jsonString: json)
        XCTAssertNotNil(request)
        do {
            _ = try JSONRPCConverter.shared.convert(request: request!)
            XCTAssertTrue(false)
        } catch {
            let jsError = error as? JSONRPCError
            XCTAssertNotNil(jsError)
            XCTAssertTrue(jsError!.code == JSONRPCError.Code.methodNotFound.rawValue)
        }
    }
}
