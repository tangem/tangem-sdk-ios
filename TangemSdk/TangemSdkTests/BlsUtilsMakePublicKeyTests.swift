//
//  BlsUtilsMakePublicKeyTests.swift
//  TangemSdk
//
//  Created by Aleksei Lobankov on 05.11.2025.
//

import Foundation
import Testing
import Bls_Signature
import TangemSdk

struct BlsUtilsMakePublicKeyTests {
    @Test("makePublicKey(from:) produces correct key for valid private key data", arguments: Self.validDataPairs)
    func makePublicKeyProducesCorrectKeyForValidData(validPrivateKeyData: Data, expectedPublicKey: String) throws {
        let publicKey = try BLSUtils().makePublicKey(from: validPrivateKeyData)
        #expect(publicKey == expectedPublicKey)
    }

    @Test("makePublicKey(from:) produces correct key for valid private key hex", arguments: Self.validHexPairs)
    func makePublicKeyProducesCorrectKeyForValidHex(validPrivateKeyHex: String, expectedPublicKey: String) throws {
        let publicKey = try BLSUtils().makePublicKey(from: validPrivateKeyHex)
        #expect(publicKey == expectedPublicKey)
    }

    @Test("makePublicKey(from:) throws correct error for invalid private key data", arguments: Self.invalidDataPairs)
    func makePublicKeyThrowsCorrectErrorForInvalidData(invalidPrivateKeyData: Data, expectedErrorCode: BlsSignatureErrorCode) throws {
        do {
            _ = try BLSUtils().makePublicKey(from: invalidPrivateKeyData)
            Issue.record("Expected to throw BlsSignatureSwift.ErrorList.errorPublicKeyFromPrivateKey")
        } catch BlsSignatureSwift.ErrorList.errorPublicKeyFromPrivateKey(let errorCode) {
            #expect(errorCode == expectedErrorCode)
        }
    }

    @Test("makePublicKey(from:) throws correct error for invalid private key hex", arguments: Self.invalidHexPairs)
    func makePublicKeyThrowsCorrectErrorForInvalidHex(invalidPrivateKeyHex: String, expectedErrorCode: BlsSignatureErrorCode) throws {
        do {
            _ = try BLSUtils().makePublicKey(from: invalidPrivateKeyHex)
            Issue.record("Expected to throw BlsSignatureSwift.ErrorList.errorPublicKeyFromPrivateKey")
        } catch BlsSignatureSwift.ErrorList.errorPublicKeyFromPrivateKey(let errorCode) {
            #expect(errorCode == expectedErrorCode)
        }
    }
}

// MARK: - Sample data

extension BlsUtilsMakePublicKeyTests {
    private enum ValidPrivateKey {
        static let allZeros = Data(repeating: 0x00, count: 32)

        static let leadingZeros = Data(
            [
                0x00, 0x00, 0x7A, 0x34, 0x91, 0x22, 0xF3, 0x58,
                0x11, 0x9C, 0xDE, 0xA5, 0x66, 0x77, 0x88, 0x90,
                0xAB, 0xCD, 0xEF, 0x01, 0x23, 0x45, 0x67, 0x89,
                0x10, 0x20, 0x30, 0x40, 0x55, 0xAA, 0xFE, 0xDC
            ]
        )

        static let highRangeBytes = Data(
            [
                0x43, 0xE1, 0xD2, 0xC3, 0xB4, 0xA5, 0x96, 0x87,
                0x78, 0x69, 0x5A, 0x4B, 0x3C, 0x2D, 0x1E, 0x0F,
                0x10, 0x21, 0x32, 0x43, 0x54, 0x65, 0x76, 0x87,
                0x98, 0xA9, 0xBA, 0xCB, 0xDC, 0xED, 0xFE, 0x0A
            ]
        )

        static let mixedPattern = Data(
            [
                0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0,
                0x0F, 0xED, 0xCB, 0xA9, 0x87, 0x65, 0x43, 0x21,
                0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88,
                0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xF1, 0x02
            ]
        )

    }

    private enum InvalidPrivateKey {
        static let tooShort = Data(repeating: UInt8.random(in: 0...255), count: 31)
        static let tooLong = Data(repeating: UInt8.random(in: 0...255), count: 33)
        static let tooHigh = Data(repeating: 0xFF, count: 32)
    }

    private enum ValidPublicKey {
        static let allZeros = "c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        static let leadingZeros = "ab5b48a8e7dfe296b419d9605a0f1f5d4e6c7c081dde1edea951a98311dfdc38aae4ab330f61f697e14fc0a154062616"
        static let highRangeBytes = "a96a5f01dd64e3d8fc598eaadd5b29a9ff85b522263894882b02edcf8ddfbdf94c6c344710745502b4e7971b2649e078"
        static let mixedPattern = "81a82616241fc968ed69825e197548b28a21a2a36e0b60dcfaa4679db6d6d502773d82b65e7b236ef4574e43068bf279"
    }

    private static let validDataPairs = [
        (ValidPrivateKey.allZeros, ValidPublicKey.allZeros),
        (ValidPrivateKey.leadingZeros, ValidPublicKey.leadingZeros),
        (ValidPrivateKey.highRangeBytes, ValidPublicKey.highRangeBytes),
        (ValidPrivateKey.mixedPattern, ValidPublicKey.mixedPattern),
    ]

    private static let validHexPairs = [
        (ValidPrivateKey.allZeros.hexString, ValidPublicKey.allZeros),
        (ValidPrivateKey.leadingZeros.hexString, ValidPublicKey.leadingZeros),
        (ValidPrivateKey.highRangeBytes.hexString, ValidPublicKey.highRangeBytes),
        (ValidPrivateKey.mixedPattern.hexString, ValidPublicKey.mixedPattern),
    ]

    private static let invalidDataPairs = [
        (InvalidPrivateKey.tooShort, BlsSignatureErrorCode.invalidByteCount),
        (InvalidPrivateKey.tooLong, BlsSignatureErrorCode.invalidByteCount),
        (InvalidPrivateKey.tooHigh, BlsSignatureErrorCode.cppInvalidArgument),
    ]

    private static let invalidHexPairs = [
        ("invalid hex string", BlsSignatureErrorCode.invalidHex),
        (InvalidPrivateKey.tooShort.hexString, BlsSignatureErrorCode.invalidByteCount),
        (InvalidPrivateKey.tooLong.hexString, BlsSignatureErrorCode.invalidByteCount),
        (InvalidPrivateKey.tooHigh.hexString, BlsSignatureErrorCode.cppInvalidArgument),
    ]
}
