//
//  SLIP10Tests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 01.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

@available(iOS 13.0, *)
class SLIP10Tests: XCTestCase {
    // test vectors for secp356k1 are equal to BIP32 test vectors
    func testSecp256k1MasterKeyGeneration() throws {
        let bip32 = BIP32()
        let masterKey = try bip32.makeMasterKey(from: Data(hexString: "000102030405060708090a0b0c0d0e0f"), curve: .secp256k1)
        XCTAssertEqual(masterKey.privateKey.hexString.lowercased(), "e8f32e723decf4051aefac8e2c93c9c5b214313817cdb01a1494b917c8436b35".lowercased())
        XCTAssertEqual(masterKey.chainCode.hexString.lowercased(), "873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508".lowercased())

        let masterKey2 = try bip32.makeMasterKey(from: Data(hexString: "fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542"), curve: .secp256k1)
        XCTAssertEqual(masterKey2.privateKey.hexString.lowercased(), "4b03d6fc340455b363f51020ad3ecca4f0850280cf436c70c727923f6db46c3e".lowercased())
        XCTAssertEqual(masterKey2.chainCode.hexString.lowercased(), "60499f801b896d83179a4374aeb7822aaeaceaa0db1f85ee3e904c4defbd9689".lowercased())
    }

    func testSecp256r1MasterKeyGeneration() throws {
        let bip32 = BIP32()
        let masterKey = try bip32.makeMasterKey(from: Data(hexString: "000102030405060708090a0b0c0d0e0f"), curve: .secp256r1)
        XCTAssertEqual(masterKey.privateKey.hexString.lowercased(), "612091aaa12e22dd2abef664f8a01a82cae99ad7441b7ef8110424915c268bc2".lowercased())
        XCTAssertEqual(masterKey.chainCode.hexString.lowercased(), "beeb672fe4621673f722f38529c07392fecaa61015c80c34f29ce8b41b3cb6ea".lowercased())

        let masterKey2 = try bip32.makeMasterKey(from: Data(hexString: "fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542"), curve: .secp256r1)
        XCTAssertEqual(masterKey2.privateKey.hexString.lowercased(), "eaa31c2e46ca2962227cf21d73a7ef0ce8b31c756897521eb6c7b39796633357".lowercased())
        XCTAssertEqual(masterKey2.chainCode.hexString.lowercased(), "96cd4465a9644e31528eda3592aa35eb39a9527769ce1855beafc1b81055e75d".lowercased())
    }

    /*func testEd25519Slip10MasterKeyGeneration() throws {
     let bip32 = BIP32()
     let masterKey = try bip32.makeMasterKey(from: Data(hexString: "000102030405060708090a0b0c0d0e0f"), curve: .ed25519)
     XCTAssertEqual(masterKey.privateKey.hexString.lowercased(), "2b4be7f19ee27bbf30c667b642d5f4aa69fd169872f8fc3059c08ebae2eb19e7".lowercased())
     XCTAssertEqual(masterKey.chainCode.hexString.lowercased(), "90046a93de5380a72b5e45010748567d5ea02bbf6522f979e05c0d8d8ca9fffb".lowercased())

     let masterKey2 = try bip32.makeMasterKey(from: Data(hexString: "fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542"), curve: .ed25519)
     XCTAssertEqual(masterKey2.privateKey.hexString.lowercased(), "171cb88b1b3c1db25add599712e36245d75bc65a1a5c9e18d76f9f2b1eab4012".lowercased())
     XCTAssertEqual(masterKey2.chainCode.hexString.lowercased(), "ef70a74db9c3a5af931b5fe73ed8e1a53464133654fd55e7a66f8570b8e33c3b".lowercased())
     }*/

    func testSecp256r1MasterKeyGenerationRetry() throws {
        let bip32 = BIP32()
        let masterKey = try bip32.makeMasterKey(from: Data(hexString: "a7305bc8df8d0951f0cb224c0e95d7707cbdf2c6ce7e8d481fec69c7ff5e9446"), curve: .secp256r1)
        XCTAssertEqual(masterKey.privateKey.hexString.lowercased(), "3b8c18469a4634517d6d0b65448f8e6c62091b45540a1743c5846be55d47d88f".lowercased())
        XCTAssertEqual(masterKey.chainCode.hexString.lowercased(), "7762f9729fed06121fd13f326884c82f59aa95c57ac492ce8c9654e60efd130c".lowercased())
    }
}
