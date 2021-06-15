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
        let testJson = getJson(for: "Scan")
        let request = try? JSONRPCRequest(jsonString: testJson.request)
        XCTAssertNotNil(request)
        let task = try? JSONRPCConverter.shared.convert(request: request!)
        XCTAssertNotNil(task)
    }
    
    func testSignConvert() {
        let testJson = getJson(for: "Sign")
        let request = try? JSONRPCRequest(jsonString: testJson.request)
        XCTAssertNotNil(request)
        let task = try? JSONRPCConverter.shared.convert(request: request!)
        XCTAssertNotNil(task)
        
        let response = SignResponse(cardId: "c000111122223333",
                                    signatures: [Data(hexString: "eb7411c2b7d871c06dad51e58e44746583ad134f4e214e4899f2fc84802232a1"),
                                                 Data(hexString: "33443bd93f350b62a90a0c23d30c6d4e9bb164606e809ccace60cf0e2591e58c")],
                                    totalSignedHashes: 2)
        
        let result: Result<SignResponse, TangemSdkError> = .success(response)
        let jsonResponse = result.toJsonResponse(id: 1).json
        
        XCTAssertEqual(jsonResponse, testJson.response)
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
    
    private func getJson(for method: String) -> (request: String, response: String) {
        (readJson(for: method + "Request"),  readJson(for: method + "Response"))
    }
    
    private func readJson(for  name: String) -> String {
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: name, ofType: "json")!
        return try! String(contentsOfFile: path)
    }
}
