//
//  CryptoSwiftUtilsTests.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 01/10/2025.
//

import XCTest
@testable import TangemSdk
import CryptoKit

class CryptoSwiftUtilsTests: XCTestCase {

    func testAESCCMRoundTrip() throws {
        let key = Data(hexString: "1BDECA766DE9D2F48A1A4C1618D666657D2CA2A27973800D3F9C6FF95EBB5725")
        let nonce = Data(hexString: "CAAA12345678900001000002")
        let associatedData = Data(hexString: "9000")
        let message = Data(hexString:"0102030405060708")
        let expectedEncrypted = Data(hexString: "0D463CF4C35809F5F98292091557BA04")

        let encrypted = try message.encryptAESCCM(with: key, iv: nonce, additionalAuthenticatedData: associatedData)
        XCTAssertEqual(encrypted, expectedEncrypted)

        let decrypted = try encrypted.decryptAESCCM(with: key, iv: nonce, additionalAuthenticatedData: associatedData)
        XCTAssertEqual(message, decrypted)
    }
}
