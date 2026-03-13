//
//  TangemSdkTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 02/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemSdk
import CryptoKit
import CommonCrypto

class CryptoUtilsTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGeneratePrivateKey() throws {
        let privateKey = try CryptoUtils.generateRandomBytes(count: 32)
        XCTAssertNotNil(privateKey)
        XCTAssertEqual(privateKey.count, 32)
    }

    func testSecp256k1Sign() throws {
        let privateKey = Data(hexString: "fd230007d4a39352f50d8c481456c1f86ddc5ff155df170af0100a62269852f0")
        let publicKey = Data(hexString: "0432f507f6a3029028faa5913838c50f5ff3355b9b000b51889d03a2bdb96570cd750e8187482a27ca9d2dd0c92c632155d0384521ed406753c9883621ad0da68c")
        let message = Data(repeating: UInt8(1), count: 64)
        let signature = try Secp256k1Utils().sign(message, with: privateKey)
        XCTAssertNotNil(signature)

        let verify = try CryptoUtils.verify(curve: .secp256k1, publicKey: publicKey, message: message, signature: signature)
        let verifyByHash = try CryptoUtils.verify(curve: .secp256k1, publicKey: publicKey, hash: message.getSHA256(), signature: signature)
        XCTAssertNotNil(verify)
        XCTAssertEqual(verify, true)
        XCTAssertNotNil(verifyByHash)
        XCTAssertEqual(verifyByHash, true)
    }

    func testEd25519Sign() throws {
        let privateKey = try CryptoUtils.generateRandomBytes(count: 32)
        let publicKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation
        let message = Data(hexString: "0DA5A5EDA1F8B4F52DA5F92C2DC40346AAFE8C180DA3AD811F6F5AE7CCFB387D")
        let signature = try message.sign(privateKey: privateKey, curve: .ed25519)

        let verify = try? CryptoUtils.verify(curve: .ed25519, publicKey: publicKey, message: message, signature: signature)
        let verifyByHash = try? CryptoUtils.verify(curve: .ed25519, publicKey: publicKey, hash: message.getSHA512(), signature: signature)
        XCTAssertNotNil(verify)
        XCTAssertNotNil(verifyByHash)
        XCTAssertEqual(verify, true)
        XCTAssertEqual(verifyByHash, true)
    }

    func testP256Sign() throws {
        let privateKey = try CryptoUtils.generateRandomBytes(count: 32)
        let publicKey = try P256.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.x963Representation
        let message = Data(hexString: "0DA5A5EDA1F8B4F52DA5F92C2DC40346AAFE8C180DA3AD811F6F5AE7CCFB387D")
        let signature = try message.sign(privateKey: privateKey, curve: .secp256r1)

        let verify = try? CryptoUtils.verify(curve: .secp256r1, publicKey: publicKey, message: message, signature: signature)
        let verifyByHash = try? CryptoUtils.verify(curve: .secp256r1, publicKey: publicKey, hash: message.getSHA256(), signature: signature)
        XCTAssertNotNil(verify)
        XCTAssertNotNil(verifyByHash)
        XCTAssertEqual(verify, true)
        XCTAssertEqual(verifyByHash, true)
    }

    func testEd25519Verify() {
        let publicKey = Data(hexString:"1C985027CBDD3326E58BF01311828588616855CBDFA15E46A20325AAE8BABE9A")
        let message = Data(hexString:"0DA5A5EDA1F8B4F52DA5F92C2DC40346AAFE8C180DA3AD811F6F5AE7CCFB387D")
        let signature = Data(hexString: "47F4C419E28013589433DBD771D618D990F4564BDAF6135039A8DF6A0803A3E3D84C3702514512C22E928C875495CA0EAC186AF0B23663924179D41830D6BF09")
        let hash = message.getSHA512()
        var verify: Bool? = nil
        var verifyByHash: Bool? = nil
        measure {
            verify = try? CryptoUtils.verify(curve: .ed25519, publicKey: publicKey, message: message, signature: signature)
            verifyByHash = try? CryptoUtils.verify(curve: .ed25519, publicKey: publicKey, hash: hash, signature: signature)
        }

        XCTAssertNotNil(verify)
        XCTAssertEqual(verify, true)
        XCTAssertNotNil(verify)
        XCTAssertEqual(verifyByHash, true)
    }

    func testP256Verify() throws {
        let privateKeyData = try CryptoUtils.generateRandomBytes(count: 32)
        let privateKey = try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
        let publicKey = privateKey.publicKey.x963Representation
        let message = Data(hexString:"0DA5A5EDA1F8B4F52DA5F92C2DC40346AAFE8C180DA3AD811F6F5AE7CCFB387D")
        let hash = message.getSHA256()
        let signature = try privateKey.signature(for: message).rawRepresentation

        var verify: Bool? = nil
        var verifyByHash: Bool? = nil
        measure {
            verify = try? CryptoUtils.verify(curve: .secp256r1, publicKey: publicKey, message: message, signature: signature)
            verifyByHash = try? CryptoUtils.verify(curve: .secp256r1, publicKey: publicKey, hash: hash, signature: signature)
        }

        XCTAssertNotNil(verify)
        XCTAssertEqual(verifyByHash, true)

        XCTAssertNotNil(verify)
        XCTAssertEqual(verifyByHash, true)
    }

    func testKeyCompression() throws {
        let publicKey = Data(hexString: "0432f507f6a3029028faa5913838c50f5ff3355b9b000b51889d03a2bdb96570cd750e8187482a27ca9d2dd0c92c632155d0384521ed406753c9883621ad0da68c")

        let compressedKey = try Secp256k1Key(with: publicKey).compress()
        XCTAssertEqual(compressedKey.hexString.lowercased(), "0232f507f6a3029028faa5913838c50f5ff3355b9b000b51889d03a2bdb96570cd")
        let decompressedKey = try Secp256k1Key(with: compressedKey).decompress()
        XCTAssertEqual(decompressedKey,publicKey)

        let testKeyCompressed = try Secp256k1Key(with: publicKey).compress()
        let testKeyCompressed2 = try Secp256k1Key(with: testKeyCompressed).compress()
        XCTAssertEqual(testKeyCompressed.hexString.lowercased(), "0232f507f6a3029028faa5913838c50f5ff3355b9b000b51889d03a2bdb96570cd")
        XCTAssertEqual(testKeyCompressed, testKeyCompressed2)
        let testKeyDecompressed = try Secp256k1Key(with: testKeyCompressed).decompress()
        let testKeyDecompressed2 = try Secp256k1Key(with: testKeyDecompressed).decompress()
        XCTAssertEqual(testKeyDecompressed, publicKey)
        XCTAssertEqual(testKeyDecompressed, testKeyDecompressed2)

        let edKey = Data(hexString:"1C985027CBDD3326E58BF01311828588616855CBDFA15E46A20325AAE8BABE9A")
        XCTAssertThrowsError(try Secp256k1Key(with: edKey).compress())
        XCTAssertThrowsError(try Secp256k1Key(with: edKey).decompress())
    }

    func testNormalize() throws {
        let sigData = Data(hexString: "5365F955FC45763383936BBC021A15D583E8D2300D1A65D21853B6A0FCAECE4ED65093BB5EC5291EC7CC95B4278D0E9EF59719DE985EEB764779F511E453EDDD")
        let sig = try Secp256k1Signature(with: sigData)

        let normalized = try sig.normalize()
        XCTAssertEqual(normalized.hexString, "5365F955FC45763383936BBC021A15D583E8D2300D1A65D21853B6A0FCAECE4E29AF6C44A13AD6E138336A4BD872F15FC517C30816E9B4C57858697AEBE25364")
    }

    func testSignatureUnmarshal() throws {
        let privateKey = Data(hexString: "fd230007d4a39352f50d8c481456c1f86ddc5ff155df170af0100a62269852f0")
        let publicKey = Data(hexString: "0432f507f6a3029028faa5913838c50f5ff3355b9b000b51889d03a2bdb96570cd750e8187482a27ca9d2dd0c92c632155d0384521ed406753c9883621ad0da68c")

        let dummyData = Data(repeating: UInt8(1), count: 64)
        let hash = dummyData.getSHA256()
        let signature = try Secp256k1Utils().sign(dummyData, with: privateKey)
        let unmarshalled = try Secp256k1Signature(with: signature).unmarshal(with: publicKey, hash: hash)
        XCTAssertEqual(unmarshalled.r.hexString, "1CF364E34E445A99AD7DBE616A93053E58C6B72A8C4F9158E506DE7C0DB3A3B3")
        XCTAssertEqual(unmarshalled.s.hexString, "4D5A1F20E671A6CC57D2A46FC28488C833B4337B5C37089B99BBC16707459BA1")
        XCTAssertEqual(unmarshalled.v.hexString, "1C")
    }

    func testRecoverPublicKey() throws {
        let privateKey = Data(hexString: "fd230007d4a39352f50d8c481456c1f86ddc5ff155df170af0100a62269852f0")
        let publicKey = Data(hexString: "0432f507f6a3029028faa5913838c50f5ff3355b9b000b51889d03a2bdb96570cd750e8187482a27ca9d2dd0c92c632155d0384521ed406753c9883621ad0da68c")
        let dummyData = Data(repeating: UInt8(1), count: 64)
        let hash = dummyData.getSHA256()

        let signature = try Secp256k1Utils().sign(dummyData, with: privateKey)
        let unmarshalled = try Secp256k1Signature(with: signature).unmarshal(with: publicKey, hash: hash)

        let key = try Secp256k1Key(with: unmarshalled, hash: hash)
        XCTAssertEqual(try key.decompress().hexString, publicKey.hexString)

        let key1 = try Secp256k1Key(with: unmarshalled, message: dummyData)
        XCTAssertEqual(try key1.decompress().hexString, publicKey.hexString)
    }

    func testSecp256k1PrivateKeyValidation() {
        let utils = Secp256k1Utils()

        XCTAssertFalse(utils.isPrivateKeyValid(Data()))
        XCTAssertFalse(utils.isPrivateKeyValid(Data(repeating: UInt8(0), count: 32)))
    }

    func testSecp256r1PrivateKeyValidation() throws {
        XCTAssertFalse(try CryptoUtils.isPrivateKeyValid(Data(), curve: .secp256r1))
        XCTAssertFalse(try CryptoUtils.isPrivateKeyValid(Data(repeating: UInt8(0), count: 32), curve: .secp256r1))
        XCTAssertFalse(try CryptoUtils.isPrivateKeyValid(Data(hexString: "FFFFFFFFFE92BF972115EB5008573E60811CA5A79B40EAAF9036189360F47413"), curve: .secp256r1))
        XCTAssertFalse(try CryptoUtils.isPrivateKeyValid(Data(hexString: "FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC4FC632551"), curve: .secp256r1))
        XCTAssertTrue(try CryptoUtils.isPrivateKeyValid(Data(hexString: "FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632550"), curve: .secp256r1))
    }

    func testSchnorrVerifyByHash() throws {
        let publicKey = Data(hexString: "208BDB9C192B5DE5DDEBA9CA8500EEC10DECB9A0980C4664F5B168F6B37EB92A")
        let hash = Data(hexString: "0000000000000000000000000000000000000000000000000000000000000000")
        let signature = Data(hexString: "735951D8481B99777AB0ABADEFDA903E485756DE3599E75AF655B7F26CB7634956DEDEB89DB3E40A7B9ED095E5855290F8EB85C22E57A001A4A64385AB11A5B3")

        let verify = try CryptoUtils.verify(curve: .bip0340, publicKey: publicKey, hash: hash, signature: signature)
        XCTAssertEqual(verify, true)
    }

    func testSchnorrVerifyByMessage() throws {
        let publicKey = Data(hexString: "DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659")
        let message = Data(hexString: "243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89")
        let signature = Data(hexString: "0560D3B34117AAE83F028AB92B3F8C16E3FDA34D55D3C7A2E1F2EDFE0A0071491D8D2302A6810FC017EE4CBF6BF13ADF36F9C0967FFCFE1A64BCBBDA73CA813B")

        let verify = try CryptoUtils.verify(curve: .bip0340, publicKey: publicKey, message: message, signature: signature)
        XCTAssertEqual(verify, true)
    }

    func testECDHbyX() throws {
        let u = Secp256k1Utils()
        let keyPair1 = try u.generateKeyPair()
        let keyPair2 = try u.generateKeyPair()
        let sharedSecret1 = try u.getSharedSecret(privateKey: keyPair1.privateKey, publicKey: keyPair2.publicKey)
        let sharedSecret2 = try u.getSharedSecret(privateKey: keyPair2.privateKey, publicKey: keyPair1.publicKey)
        XCTAssertEqual(sharedSecret1, sharedSecret2)
    }

    // MARK: - Secp256k1Utils.serializeDer

    func testSerializeDer() throws {
        let privateKey = Data(hexString: "fd230007d4a39352f50d8c481456c1f86ddc5ff155df170af0100a62269852f0")
        let message = Data(repeating: UInt8(1), count: 64)
        let signature = try Secp256k1Utils().sign(message, with: privateKey)

        // Test via Secp256k1Utils directly
        let der = try Secp256k1Utils().serializeDer(signature)
        XCTAssertFalse(der.isEmpty)
        // DER signatures start with 0x30 (SEQUENCE tag)
        XCTAssertEqual(der[0], 0x30)

        // Test via Secp256k1Signature wrapper
        let sig = try Secp256k1Signature(with: signature)
        let derFromWrapper = try sig.serializeDer()
        XCTAssertEqual(der, derFromWrapper)
    }

    func testSerializeDerDeterministic() throws {
        let privateKey = Data(hexString: "fd230007d4a39352f50d8c481456c1f86ddc5ff155df170af0100a62269852f0")
        let message = Data(repeating: UInt8(2), count: 32)
        let signature = try Secp256k1Utils().sign(message, with: privateKey)

        let der1 = try Secp256k1Utils().serializeDer(signature)
        let der2 = try Secp256k1Utils().serializeDer(signature)
        XCTAssertEqual(der1, der2)
    }

    // MARK: - Secp256k1Utils.sum

    func testSumPublicKeys() throws {
        let u = Secp256k1Utils()
        let keyPair1 = try u.generateKeyPair()
        let keyPair2 = try u.generateKeyPair()

        let compressed1 = try u.compressKey(keyPair1.publicKey)
        let compressed2 = try u.compressKey(keyPair2.publicKey)

        let sumKey = try u.sum(compressedPubKey1: compressed1, compressedPubKey2: compressed2)
        // Result should be a compressed public key (33 bytes)
        XCTAssertEqual(sumKey.count, 33)
        // Should start with 02 or 03
        XCTAssertTrue(sumKey[0] == 0x02 || sumKey[0] == 0x03)
    }

    func testSumPublicKeysCommutative() throws {
        let u = Secp256k1Utils()
        let keyPair1 = try u.generateKeyPair()
        let keyPair2 = try u.generateKeyPair()

        let compressed1 = try u.compressKey(keyPair1.publicKey)
        let compressed2 = try u.compressKey(keyPair2.publicKey)

        let sum1 = try u.sum(compressedPubKey1: compressed1, compressedPubKey2: compressed2)
        let sum2 = try u.sum(compressedPubKey1: compressed2, compressedPubKey2: compressed1)
        XCTAssertEqual(sum1, sum2)
    }

    // MARK: - Secp256k1Utils.generateKeyPair

    func testGenerateKeyPair() throws {
        let u = Secp256k1Utils()
        let keyPair = try u.generateKeyPair()

        // Private key should be 32 bytes
        XCTAssertEqual(keyPair.privateKey.count, 32)
        // Public key should be uncompressed (65 bytes, starts with 0x04)
        XCTAssertEqual(keyPair.publicKey.count, 65)
        XCTAssertEqual(keyPair.publicKey[0], 0x04)
        // Key should be valid
        XCTAssertTrue(u.isPrivateKeyValid(keyPair.privateKey))
    }

    // MARK: - Secp256k1Utils.compressKey/decompressKey no-op paths

    func testCompressKeyAlreadyCompressed() throws {
        let u = Secp256k1Utils()
        let keyPair = try u.generateKeyPair()
        let compressed = try u.compressKey(keyPair.publicKey)
        XCTAssertEqual(compressed.count, 33)

        // Compressing an already-compressed key should return the same data
        let compressed2 = try u.compressKey(compressed)
        XCTAssertEqual(compressed, compressed2)
    }

    func testDecompressKeyAlreadyDecompressed() throws {
        let u = Secp256k1Utils()
        let keyPair = try u.generateKeyPair()
        XCTAssertEqual(keyPair.publicKey.count, 65)

        // Decompressing an already-decompressed key should return the same data
        let decompressed = try u.decompressKey(keyPair.publicKey)
        XCTAssertEqual(keyPair.publicKey, decompressed)
    }

    // MARK: - Secp256k1Utils.createXOnlyPublicKey

    func testCreateXOnlyPublicKey() throws {
        let u = Secp256k1Utils()
        let keyPair = try u.generateKeyPair()
        let xOnly = try u.createXOnlyPublicKey(privateKey: keyPair.privateKey)
        // x-only public key is 32 bytes
        XCTAssertEqual(xOnly.count, 32)
    }

    func testCreateXOnlyPublicKeyInvalidKey() {
        let u = Secp256k1Utils()
        XCTAssertThrowsError(try u.createXOnlyPublicKey(privateKey: Data(repeating: 0, count: 32)))
    }

    // MARK: - Secp256k1 private key validation edge cases

    func testSecp256k1ValidPrivateKey() throws {
        let u = Secp256k1Utils()
        let keyPair = try u.generateKeyPair()
        XCTAssertTrue(u.isPrivateKeyValid(keyPair.privateKey))
    }

    func testSecp256k1PrivateKeyValidationCurveOrder() {
        let u = Secp256k1Utils()
        // secp256k1 curve order n
        let curveOrder = Data(hexString: "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141")
        XCTAssertFalse(u.isPrivateKeyValid(curveOrder))
        // n+1 should also be invalid
        XCTAssertFalse(u.isPrivateKeyValid(Data(hexString: "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364142")))
    }

    // MARK: - CryptoUtils.makePublicKey for secp256k1/bip0340

    func testMakePublicKeySecp256k1() throws {
        let privateKey = Data(hexString: "fd230007d4a39352f50d8c481456c1f86ddc5ff155df170af0100a62269852f0")
        let publicKey = try CryptoUtils.makePublicKey(from: privateKey, curve: .secp256k1)
        // makePublicKey for secp256k1 returns compressed key (33 bytes)
        XCTAssertEqual(publicKey.count, 33)
        XCTAssertTrue(publicKey[0] == 0x02 || publicKey[0] == 0x03)
    }

    func testMakePublicKeyBip0340() throws {
        let privateKey = Data(hexString: "fd230007d4a39352f50d8c481456c1f86ddc5ff155df170af0100a62269852f0")
        let publicKey = try CryptoUtils.makePublicKey(from: privateKey, curve: .bip0340)
        // bip0340 returns x-only key (32 bytes)
        XCTAssertEqual(publicKey.count, 32)
    }

    // MARK: - CryptoUtils.isPrivateKeyValid for ed25519

    func testIsPrivateKeyValidEd25519() throws {
        let validKey = try CryptoUtils.generateRandomBytes(count: 32)
        XCTAssertTrue(try CryptoUtils.isPrivateKeyValid(validKey, curve: .ed25519))
        XCTAssertTrue(try CryptoUtils.isPrivateKeyValid(validKey, curve: .ed25519_slip0010))
    }

    func testIsPrivateKeyValidEd25519ExtendedKeyThrows() {
        // Extended private keys (> 32 bytes) should throw for ed25519
        let extendedKey = Data(repeating: 0x01, count: 64)
        XCTAssertThrowsError(try CryptoUtils.isPrivateKeyValid(extendedKey, curve: .ed25519))
    }

    func testIsPrivateKeyValidBip0340() throws {
        let validKey = Data(hexString: "fd230007d4a39352f50d8c481456c1f86ddc5ff155df170af0100a62269852f0")
        XCTAssertTrue(try CryptoUtils.isPrivateKeyValid(validKey, curve: .bip0340))
        XCTAssertFalse(try CryptoUtils.isPrivateKeyValid(Data(), curve: .bip0340))
    }

    // MARK: - CryptoUtils.verify secp256r1 with compressed key (33 bytes)

    /// Verify by message with compressed secp256r1 key.
    func testVerifyByMessageSecp256r1CompressedKey() throws {
        let privateKey = try P256.Signing.PrivateKey(rawRepresentation: CryptoUtils.generateRandomBytes(count: 32))
        let compressedPublicKey = privateKey.publicKey.compressedRepresentation
        XCTAssertEqual(compressedPublicKey.count, 33)

        let message = Data(hexString: "0DA5A5EDA1F8B4F52DA5F92C2DC40346AAFE8C180DA3AD811F6F5AE7CCFB387D")
        let signature = try privateKey.signature(for: message).rawRepresentation

        XCTAssertTrue(try CryptoUtils.verify(curve: .secp256r1, publicKey: compressedPublicKey, message: message, signature: signature))
    }

    /// Verify by hash with compressed secp256r1 key.
    func testVerifyByHashSecp256r1CompressedKey() throws {
        let privateKey = try P256.Signing.PrivateKey(rawRepresentation: CryptoUtils.generateRandomBytes(count: 32))
        let compressedPublicKey = privateKey.publicKey.compressedRepresentation
        XCTAssertEqual(compressedPublicKey.count, 33)

        let message = Data(hexString: "0DA5A5EDA1F8B4F52DA5F92C2DC40346AAFE8C180DA3AD811F6F5AE7CCFB387D")
        let hash = message.getSHA256()
        let signature = try privateKey.signature(for: CustomSha256Digest(hash: hash)).rawRepresentation
        XCTAssertTrue(try CryptoUtils.verify(curve: .secp256r1, publicKey: compressedPublicKey, hash: hash, signature: signature))
    }

    /// Verify by message with compressed secp256r1 key and WRONG signature — ensures
    /// that once compressed key support is added, invalid signatures are correctly rejected.
    func testVerifyByMessageSecp256r1CompressedKeyWrongSignature() throws {
        let privateKey = try P256.Signing.PrivateKey(rawRepresentation: CryptoUtils.generateRandomBytes(count: 32))
        let compressedPublicKey = privateKey.publicKey.compressedRepresentation

        let message = Data(hexString: "0DA5A5EDA1F8B4F52DA5F92C2DC40346AAFE8C180DA3AD811F6F5AE7CCFB387D")
        let wrongMessage = Data(hexString: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
        let wrongSignature = try privateKey.signature(for: wrongMessage).rawRepresentation

        XCTAssertFalse(try CryptoUtils.verify(curve: .secp256r1, publicKey: compressedPublicKey, message: message, signature: wrongSignature))
    }

    /// Verify by hash with compressed secp256r1 key and WRONG public key — ensures
    /// that once compressed key support is added, wrong keys are correctly rejected.
    func testVerifyByHashSecp256r1CompressedKeyWrongKey() throws {
        let privateKey1 = try P256.Signing.PrivateKey(rawRepresentation: CryptoUtils.generateRandomBytes(count: 32))
        let privateKey2 = try P256.Signing.PrivateKey(rawRepresentation: CryptoUtils.generateRandomBytes(count: 32))
        let wrongCompressedPublicKey = privateKey2.publicKey.compressedRepresentation

        let message = Data(hexString: "0DA5A5EDA1F8B4F52DA5F92C2DC40346AAFE8C180DA3AD811F6F5AE7CCFB387D")
        let hash = message.getSHA256()
        let signature = try privateKey1.signature(for: CustomSha256Digest(hash: hash)).rawRepresentation

        // Precondition: wrong key does NOT verify
        XCTAssertFalse(try CryptoUtils.verify(curve: .secp256r1, publicKey: wrongCompressedPublicKey, hash: hash, signature: signature))
    }

    // MARK: - Verification with wrong key/data returns false

    func testSecp256k1VerifyWrongPublicKeyReturnsFalse() throws {
        let u = Secp256k1Utils()
        let keyPair1 = try u.generateKeyPair()
        let keyPair2 = try u.generateKeyPair()
        let message = Data(repeating: UInt8(1), count: 64)
        let signature = try u.sign(message, with: keyPair1.privateKey)

        // Verify with wrong public key should return false
        let result = try CryptoUtils.verify(curve: .secp256k1, publicKey: keyPair2.publicKey, message: message, signature: signature)
        XCTAssertFalse(result)
    }

    func testSecp256k1VerifyWrongMessageReturnsFalse() throws {
        let privateKey = Data(hexString: "fd230007d4a39352f50d8c481456c1f86ddc5ff155df170af0100a62269852f0")
        let publicKey = Data(hexString: "0432f507f6a3029028faa5913838c50f5ff3355b9b000b51889d03a2bdb96570cd750e8187482a27ca9d2dd0c92c632155d0384521ed406753c9883621ad0da68c")
        let message = Data(repeating: UInt8(1), count: 64)
        let wrongMessage = Data(repeating: UInt8(2), count: 64)
        let signature = try Secp256k1Utils().sign(message, with: privateKey)

        let result = try CryptoUtils.verify(curve: .secp256k1, publicKey: publicKey, message: wrongMessage, signature: signature)
        XCTAssertFalse(result)
    }

    // MARK: - SchnorrSignature invalid init

    func testSchnorrSignatureInvalidSize() {
        XCTAssertThrowsError(try SchnorrSignature(with: Data(repeating: 0, count: 32)))
        XCTAssertThrowsError(try SchnorrSignature(with: Data(repeating: 0, count: 65)))
        XCTAssertThrowsError(try SchnorrSignature(with: Data()))
    }

    // MARK: - Secp256k1Signature.Extended

    func testSignatureExtendedDataProperty() throws {
        let privateKey = Data(hexString: "fd230007d4a39352f50d8c481456c1f86ddc5ff155df170af0100a62269852f0")
        let publicKey = Data(hexString: "0432f507f6a3029028faa5913838c50f5ff3355b9b000b51889d03a2bdb96570cd750e8187482a27ca9d2dd0c92c632155d0384521ed406753c9883621ad0da68c")
        let message = Data(repeating: UInt8(1), count: 64)
        let hash = message.getSHA256()
        let signature = try Secp256k1Utils().sign(message, with: privateKey)

        let extended = try Secp256k1Signature(with: signature).unmarshal(with: publicKey, hash: hash)
        // data should be r + s + v
        XCTAssertEqual(extended.data, extended.r + extended.s + extended.v)
        XCTAssertEqual(extended.data.count, 65)
    }

    // MARK: - Data.sign for secp256k1

    func testDataSignSecp256k1() throws {
        let privateKey = Data(hexString: "fd230007d4a39352f50d8c481456c1f86ddc5ff155df170af0100a62269852f0")
        let publicKey = Data(hexString: "0432f507f6a3029028faa5913838c50f5ff3355b9b000b51889d03a2bdb96570cd750e8187482a27ca9d2dd0c92c632155d0384521ed406753c9883621ad0da68c")
        let message = Data(repeating: UInt8(3), count: 32)

        // Default curve is secp256k1
        let signature = try message.sign(privateKey: privateKey)
        XCTAssertEqual(signature.count, 64)

        let verified = try CryptoUtils.verify(curve: .secp256k1, publicKey: publicKey, message: message, signature: signature)
        XCTAssertTrue(verified)
    }

    // MARK: - CryptoUtils.crypt (AES)

    func testCryptRoundTrip() throws {
        let key = try CryptoUtils.generateRandomBytes(count: 32)
        let plaintext = Data("Hello World!".utf8)

        let encrypted = try CryptoUtils.crypt(
            operation: kCCEncrypt,
            algorithm: kCCAlgorithmAES,
            options: kCCOptionPKCS7Padding,
            key: key,
            dataIn: plaintext
        )
        XCTAssertNotEqual(encrypted, plaintext)

        let decrypted = try CryptoUtils.crypt(
            operation: kCCDecrypt,
            algorithm: kCCAlgorithmAES,
            options: kCCOptionPKCS7Padding,
            key: key,
            dataIn: encrypted
        )
        XCTAssertEqual(decrypted, plaintext)
    }
}

// MARK: - Helper for tests

fileprivate struct CustomSha256Digest: Digest {
    static var byteCount: Int { 32 }

    let hash: Data

    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try hash.withUnsafeBytes(body)
    }
}
