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
    
    func testInitialMessageInit() {
        let json = "{\"header\": \"Some header\", \"body\": \"Some body\"}"
        
        if let message = Message(json) {
            XCTAssertEqual(message.header, "Some header")
            XCTAssertEqual(message.body, "Some body")
        } else {
            XCTAssertNotNil(nil)
        }
    }
    
    func testJsonResponse() {
        let response = SuccessResponse(cardId: "c000111122223333")
        let result: Result<SuccessResponse, TangemSdkError> = .success(response)
        let jsonResponse = result.toJsonResponse(id: 1).json
        let testResponse =
            """
            {
              "jsonrpc" : "2.0",
              "result" : {
                "cardId" : "c000111122223333"
              },
              "id" : 1
            }
            """
        XCTAssertEqual(jsonResponse, testResponse)
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
    
//    func testScan() {
//        let testJson = getTestData(for: "Scan", resultType: ScanTask.Response.self)
//        let request = try? JSONRPCRequest(jsonString: testJson.request)
//        XCTAssertNotNil(request)
//
//        let task = try? JSONRPCConverter.shared.convert(request: request!)
//        XCTAssertNotNil(task)
//    }
    
    func testSignHashes() {
        let result = SignHashesResponse(cardId: "c000111122223333",
                                        signatures: [Data(hexString: "eb7411c2b7d871c06dad51e58e44746583ad134f4e214e4899f2fc84802232a1"),
                                                     Data(hexString: "33443bd93f350b62a90a0c23d30c6d4e9bb164606e809ccace60cf0e2591e58c")],
                                        totalSignedHashes: 2)
        
        testMethod(name: "SignHashes", result: result)
    }
    
    func testSignHash() {
        let result = SignHashResponse(cardId: "c000111122223333",
                                      signature: Data(hexString: "eb7411c2b7d871c06dad51e58e44746583ad134f4e214e4899f2fc84802232a1"),
                                      totalSignedHashes: 2)
        
        testMethod(name: "SignHash", result: result)
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
    
    private func testMethod<TResult>(name: String, result: TResult) where TResult: Equatable & Decodable {
        guard let testData = getTestData(for: name) else { return }
        
        //test request
        let request = try? JSONRPCRequest(jsonString: testData.request)
        XCTAssertNotNil(request)
        if request == nil { return }
        
        //test convert request
        let task = try? JSONRPCConverter.shared.convert(request: request!)
        XCTAssertNotNil(task)
        
        //test response
        guard let responseJson = try? JSONSerialization.jsonObject(with: testData.response, options: []) as? [String: Any],
              let resultValue = responseJson["result"],
              let resultData = try? JSONSerialization.data(withJSONObject: resultValue, options: .prettyPrinted) else {
            XCTAssertNotNil(nil)
            return
        }
        
        guard let testResult = try? JSONDecoder.tangemSdkDecoder.decode(TResult.self, from: resultData)  else {
            XCTAssertNotNil(nil)
            return
        }
        
        XCTAssertEqual(result, testResult)
    }
    
    private func getTestData(for method: String) -> (request: String, response: Data)? {
        let fileText = readFile(name: method)
        let jsonData = fileText.data(using: .utf8)!
        
        guard let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [Any],
              let requestData = try? JSONSerialization.data(withJSONObject: json[0], options: .prettyPrinted),
              let responseData = try? JSONSerialization.data(withJSONObject: json[1], options: .prettyPrinted),
              let requestValue = String(data: requestData, encoding: .utf8) else {
            XCTAssertNotNil(nil)
            return nil
        }
        
      
  
//        guard let re
//
//            if let requestValue = json[0] as? String {
//
//            } else {
//                XCTAssertNotNil(nil)
//                return nil
//            }
//
//
//            else {
//                throw JSONRPCError(.invalidRequest, data: "jsonrpc")
//            }
//            if let idValue = json["id"] as? Int {
//                id = idValue
//            } else {
//                throw JSONRPCError(.invalidRequest, data: "id")
//            }
//            if let methodValue = json["method"] as? String {
//                method = methodValue
//            } else {
//                throw JSONRPCError(.invalidRequest, data: "method")
//            }
//            if let paramsValue = json["params"] as? [String:Any] {
//                params = paramsValue
//            } else {
//                throw JSONRPCError(.invalidRequest, data: "params")
//            }
//
//
//
//        let jsons = try! JSONDecoder.tangemSdkDecoder.decode([String].self, from: json)
//        let resultData = jsons[1].data(using: .utf8)!
//        let result = try! JSONDecoder.tangemSdkDecoder.decode(T.self, from: resultData)
        
//        let requestJson = readJson(for: method + "Request")
//        let resultJson =  readJson(for: method + "Result").data(using: .utf8)!
//        let result = try! JSONDecoder.tangemSdkDecoder.decode(T.self, from: resultJson)
        return (requestValue, responseData)
    }
    
    private func readFile(name: String) -> String {
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: name, ofType: "json")!
        return try! String(contentsOfFile: path)
    }
}
