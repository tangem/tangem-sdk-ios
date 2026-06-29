//
//  WalletDataTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 16/03/2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class WalletDataTests: XCTestCase {
    func testCodableRoundTrip() throws {
        let token = WalletData.Token(
            name: "USD Coin",
            symbol: "USDC",
            contractAddress: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
            decimals: 6
        )
        let original = WalletData(blockchain: "ETH", token: token)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WalletData.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.blockchain, "ETH")
        XCTAssertEqual(decoded.token?.symbol, "USDC")
        XCTAssertEqual(decoded.token?.decimals, 6)
    }

    func testCodableWithoutToken() throws {
        let original = WalletData(blockchain: "BTC", token: nil)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WalletData.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertNil(decoded.token)
    }

    func testEquatable() {
        let a = WalletData(blockchain: "ETH", token: nil)
        let b = WalletData(blockchain: "ETH", token: nil)
        let c = WalletData(blockchain: "BTC", token: nil)

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    func testHashable() {
        let token = WalletData.Token(name: "T", symbol: "T", contractAddress: "0x1", decimals: 18)
        let a = WalletData(blockchain: "ETH", token: token)
        let b = WalletData(blockchain: "ETH", token: token)

        var set = Set<WalletData>()
        set.insert(a)
        set.insert(b)

        XCTAssertEqual(set.count, 1)
    }
}
