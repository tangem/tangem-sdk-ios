//
//  BLSTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 25.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

@available(iOS 13.0, *)
class BLSTests: XCTestCase {
    func testCase0() throws {
        let key = try BLSUtils().generateKey(inputKeyMaterial: Data(hexString: "c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04"))

        XCTAssertEqual(key.hexString, "6083874454709270928345386274498605044986640685124978867557563392430687146096".data(using: .utf8)!.hexString)
    }

    func testCase1() throws {
        let key = try BLSUtils().generateKey(inputKeyMaterial: Data(hexString: "0x3141592653589793238462643383279502884197169399375105820974944592"))

        XCTAssertEqual(key.hexString, "29757020647961307431480504535336562678282505419141012933316116377660817309383".data(using: .utf8)!.hexString)
    }

    func testCase2() throws {
        let key = try BLSUtils().generateKey(inputKeyMaterial: Data(hexString: "0x0099FF991111002299DD7744EE3355BBDD8844115566CC55663355668888CC00"))

        XCTAssertEqual(key.hexString, "27580842291869792442942448775674722299803720648445448686099262467207037398656".data(using: .utf8)!.hexString)
    }

    func testCase3() throws {
        let key = try BLSUtils().generateKey(inputKeyMaterial: Data(hexString: "0xd4e56740f876aef8c010b86a40d5f56745a118d0906a34e69aec8c0db1cb8fa3"))

        XCTAssertEqual(key.hexString, "19022158461524446591288038168518313374041767046816487870552872741050760015818".data(using: .utf8)!.hexString)
    }
}
