//
//  DerivedKeysTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 16/03/2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class DerivedKeysTests: XCTestCase {

    // MARK: - Subscript

    func testSubscriptGet() throws {
        let path = try DerivationPath(rawPath: "m/44'/0'")
        let key = try makeExtendedPublicKey()
        let derivedKeys = DerivedKeys(keys: [path: key])

        XCTAssertNotNil(derivedKeys[path])
        XCTAssertEqual(derivedKeys[path]?.publicKey, key.publicKey)
    }

    func testSubscriptGetMissing() throws {
        let path = try DerivationPath(rawPath: "m/44'/0'")
        let derivedKeys = DerivedKeys(keys: [:])

        XCTAssertNil(derivedKeys[path])
    }

    func testSubscriptSet() throws {
        let path = try DerivationPath(rawPath: "m/44'/0'")
        let key = try makeExtendedPublicKey()
        var derivedKeys: DerivedKeys = [:]
        derivedKeys[path] = key

        XCTAssertNotNil(derivedKeys[path])
    }

    // MARK: - ExpressibleByDictionaryLiteral

    func testEmptyLiteral() {
        let derivedKeys: DerivedKeys = [:]
        XCTAssertTrue(derivedKeys.keys.isEmpty)
    }

    // MARK: - Codable

    func testCodableRoundTrip() throws {
        let path = try DerivationPath(rawPath: "m/44'/0'")
        let key = try makeExtendedPublicKey()
        let original = DerivedKeys(keys: [path: key])

        let data = try JSONEncoder.tangemSdkEncoder.encode(original)
        let decoded = try JSONDecoder.tangemSdkDecoder.decode(DerivedKeys.self, from: data)

        XCTAssertEqual(decoded.keys.count, 1)
        XCTAssertNotNil(decoded[path])
        XCTAssertEqual(decoded[path]?.publicKey, key.publicKey)
    }

    func testDecodeEmptyDictionary() throws {
        let data = Data("{}".utf8)
        let decoded = try JSONDecoder.tangemSdkDecoder.decode(DerivedKeys.self, from: data)

        XCTAssertTrue(decoded.keys.isEmpty)
    }

    // MARK: - Helpers

    private func makeExtendedPublicKey() throws -> ExtendedPublicKey {
        try ExtendedPublicKey(
            publicKey: Data(hexString: "0440C533E007D029C1F345CA70A9F6016EC7A95C775B6320AE84248F20B647FBBD90FF56A2D9C3A1984279ED2367274A49079789E130444541C2F15907D5570B49"),
            chainCode: Data(repeating: 0, count: 32),
            depth: 0,
            parentFingerprint: Data(repeating: 0, count: 4),
            childNumber: 0
        )
    }
}
