//
//  EllipticCurveTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 16/03/2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class EllipticCurveTests: XCTestCase {
    // MARK: - supportsDerivation

    func testSupportsDerivation() {
        let supported: [EllipticCurve] = [.secp256k1, .ed25519, .ed25519_slip0010, .secp256r1, .bip0340]
        let unsupported: [EllipticCurve] = [.bls12381_G2, .bls12381_G2_AUG, .bls12381_G2_POP]

        for curve in supported {
            XCTAssertTrue(curve.supportsDerivation, "\(curve) should support derivation")
        }

        for curve in unsupported {
            XCTAssertFalse(curve.supportsDerivation, "\(curve) should not support derivation")
        }
    }

    // MARK: - StringCodable

    func testDecodeCaseInsensitive() throws {
        struct Wrapper: Codable {
            let curve: EllipticCurve
        }

        let variations = ["Secp256k1", "secp256k1", "Ed25519", "ed25519", "Secp256r1", "Bip0340"]
        let expected: [EllipticCurve] = [.secp256k1, .secp256k1, .ed25519, .ed25519, .secp256r1, .bip0340]

        for (json, expectedCurve) in zip(variations, expected) {
            let data = Data("{\"curve\":\"\(json)\"}".utf8)
            let decoded = try JSONDecoder.tangemSdkDecoder.decode(Wrapper.self, from: data)
            XCTAssertEqual(decoded.curve, expectedCurve, "Failed to decode \(json)")
        }
    }

    func testDecodeInvalidValueThrows() {
        struct Wrapper: Codable {
            let curve: EllipticCurve
        }

        let data = Data("{\"curve\":\"invalidCurve\"}".utf8)
        XCTAssertThrowsError(try JSONDecoder.tangemSdkDecoder.decode(Wrapper.self, from: data))
    }

    func testEncodeDecodeRoundTrip() throws {
        struct Wrapper: Codable {
            let curve: EllipticCurve
        }

        for curve in EllipticCurve.allCases {
            let original = Wrapper(curve: curve)
            let data = try JSONEncoder.tangemSdkEncoder.encode(original)
            let decoded = try JSONDecoder.tangemSdkDecoder.decode(Wrapper.self, from: data)
            XCTAssertEqual(decoded.curve, curve)
        }
    }
}
