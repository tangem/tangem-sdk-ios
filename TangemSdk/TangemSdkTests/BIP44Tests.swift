//
//  BIP44Tests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 16/03/2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class BIP44Tests: XCTestCase {
    func testBuildPathBitcoin() {
        let bip44 = BIP44(coinType: 0, account: 0, change: .external, addressIndex: 0)
        let path = bip44.buildPath()

        XCTAssertEqual(path.rawPath, "m/44'/0'/0'/0/0")
        XCTAssertEqual(path.nodes.count, 5)
        XCTAssertTrue(path.nodes[0].isHardened)
        XCTAssertTrue(path.nodes[1].isHardened)
        XCTAssertTrue(path.nodes[2].isHardened)
        XCTAssertFalse(path.nodes[3].isHardened)
        XCTAssertFalse(path.nodes[4].isHardened)
    }

    func testBuildPathEthereum() {
        let bip44 = BIP44(coinType: 60, account: 0, change: .external, addressIndex: 0)
        let path = bip44.buildPath()

        XCTAssertEqual(path.rawPath, "m/44'/60'/0'/0/0")
    }

    func testBuildPathInternalChain() {
        let bip44 = BIP44(coinType: 0, account: 0, change: .internal, addressIndex: 0)
        let path = bip44.buildPath()

        XCTAssertEqual(path.rawPath, "m/44'/0'/0'/1/0")
    }

    func testBuildPathNonZeroAccountAndIndex() {
        let bip44 = BIP44(coinType: 0, account: 3, change: .external, addressIndex: 7)
        let path = bip44.buildPath()

        XCTAssertEqual(path.rawPath, "m/44'/0'/3'/0/7")
    }

    func testConvenienceInitDefaults() {
        let bip44 = BIP44(coinType: 60)
        let path = bip44.buildPath()

        XCTAssertEqual(path.rawPath, "m/44'/60'/0'/0/0")
    }

    func testChainIndex() {
        XCTAssertEqual(BIP44.Chain.external.index, 0)
        XCTAssertEqual(BIP44.Chain.internal.index, 1)
    }

    func testPurposeConstant() {
        XCTAssertEqual(BIP44.purpose, 44)
    }
}
