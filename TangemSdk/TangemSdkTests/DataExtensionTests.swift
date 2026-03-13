//
//  UtilsTest.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 31.10.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//
import XCTest
@testable import TangemSdk

class DataExtensionTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testSha256() {
        let testData = Data(repeating: UInt8(5), count: 64)
        let shaCryptoKit =  testData.getSHA256()
        XCTAssertEqual(shaCryptoKit, Data(hexString: "B1BCCCF15ED0A0BD63635AE686AF9F75E522AB057C928E39F65EE83048D72C75"))
    }
    
    func testSha512() {
        let testData = Data(repeating: UInt8(5), count: 64)
        let shaCryptoKit =  testData.getSHA512()
        XCTAssertEqual(shaCryptoKit, Data(hexString: "856079398BE994391989EA610BA54AEDA815948C9C6F06B2728D46871D666841EBBC9179CD6DA2E8D86CE746E63D260C81DEB3AF51E0A790E1DF5B72597F85C6"))
    }
    
    func testSha256CryptoKitPerfomance() throws {
        let testData = try CryptoUtils.generateRandomBytes(count: 256)
        measure {
            _ = testData.getSHA256()
        }
    }
    
    func testBytesConversion() {
        let testData = Data(repeating: UInt8(2), count: 3)
        let testArray = Array.init(repeating: UInt8(2), count: 3)
        XCTAssertEqual(testData.toBytes, testArray)
    }
    
    func testToDateString() {
        let testData = Data(hexString: "07E2071B")
        let testDate = "Jul 27, 2018"
        XCTAssertEqual(testDate, testData.toDate()?.toString(locale: Locale(identifier: "en_US")))
        
        let testData1 = Data(hexString: "07E2071B1E")
        let testDate1 = "Jul 27, 2018"
        XCTAssertEqual(testDate1, testData1.toDate()?.toString(locale: Locale(identifier: "en_US")))
        
        XCTAssertNil(Data(hexString: "07E207").toDate())
    }
    
    func testFromHexConversion() {
        let testData = Data([UInt8(0x07),UInt8(0xE2),UInt8(0x07),UInt8(0x1B)])
        XCTAssertEqual(testData, Data(hexString: "07E2071B"))
    }
    
    func testToHexConversion() {
        let testData = Data([UInt8(0x07),UInt8(0xE2),UInt8(0x07),UInt8(0x1B)])
        let hex = testData.hexString
        XCTAssertEqual(hex, "07E2071B")
    }
    
    func testToUtf8Conversion() {
        let testData = Data(hexString: "736563703235366B3100")
        let testString = "secp256k1"
        let converted = testData.utf8String
        XCTAssertNotNil(converted)
        XCTAssertEqual(converted, testString)
    }
    
    func testToIntConversion() {
        let testData = Data(hexString: "00026A03")
        let intData = 158211
        let converted = testData.toInt()
        XCTAssertEqual(converted, intData)
    }
    
    func testUpperCasePrefixToIntConversion() {
        let testData = Data(hexString: "0X00026A03")
        let intData = 158211
        let converted = testData.toInt()
        XCTAssertEqual(converted, intData)
    }
    
    func testLowerCasePrefixToIntConversion() {
        let testData = Data(hexString: "0x00026A03")
        let intData = 158211
        let converted = testData.toInt()
        XCTAssertEqual(converted, intData)
    }

    // MARK: - DoubleSHA256

    func testDoubleSha256() {
        let data = Data("abc".utf8)
        let expected = data.getSHA256().getSHA256()
        XCTAssertEqual(data.getDoubleSHA256(), expected)
    }

    // MARK: - bitsString init

    func testBitsStringInit() {
        // "11111111" = 0xFF, "00000000" = 0x00
        let data = Data(bitsString: "1111111100000000")
        XCTAssertNotNil(data)
        XCTAssertEqual(data, Data([0xFF, 0x00]))
    }

    func testBitsStringInitInvalidLength() {
        // Not a multiple of 8
        let data = Data(bitsString: "1111")
        XCTAssertNil(data)
    }

    func testBitsStringInitInvalidCharacters() {
        // Contains non-binary characters
        let data = Data(bitsString: "1234567X")
        XCTAssertNil(data)
    }

    func testBitsStringInitEmpty() {
        let data = Data(bitsString: "")
        XCTAssertNotNil(data)
        XCTAssertEqual(data, Data())
    }

    // MARK: - toBits

    func testToBits() {
        let data = Data([0xFF])
        let bits = data.toBits()
        XCTAssertEqual(bits, ["1", "1", "1", "1", "1", "1", "1", "1"])
    }

    func testToBitsMultipleBytes() {
        let data = Data([0x00, 0xFF])
        let bits = data.toBits()
        XCTAssertEqual(bits.count, 16)
        XCTAssertEqual(bits.prefix(8).map { $0 }, ["0", "0", "0", "0", "0", "0", "0", "0"])
        XCTAssertEqual(bits.suffix(8).map { $0 }, ["1", "1", "1", "1", "1", "1", "1", "1"])
    }

    // MARK: - CRC16

    func testCrc16() {
        let data = Data([0x01, 0x02, 0x03])
        let crc = data.crc16()
        XCTAssertEqual(crc.count, 2)
        // Verify determinism
        XCTAssertEqual(data.crc16(), data.crc16())
    }

    func testCrc16EmptyData() {
        let data = Data()
        let crc = data.crc16()
        XCTAssertEqual(crc.count, 2)
        // ITU-V.41 init value 0x6363 → should produce [0x63, 0x63]
        XCTAssertEqual(crc, Data([0x63, 0x63]))
    }

    func testCrc16DifferentDataDifferentCRC() {
        let data1 = Data([0x01, 0x02])
        let data2 = Data([0x03, 0x04])
        XCTAssertNotEqual(data1.crc16(), data2.crc16())
    }

    // MARK: - XOR

    func testXor() throws {
        let a = Data([0xFF, 0x00, 0xAA])
        let b = Data([0x00, 0xFF, 0x55])
        let result = try a.xor(with: b)
        XCTAssertEqual(result, Data([0xFF, 0xFF, 0xFF]))
    }

    func testXorWithSelf() throws {
        let data = Data([0xAB, 0xCD, 0xEF])
        let result = try data.xor(with: data)
        XCTAssertEqual(result, Data([0x00, 0x00, 0x00]))
    }

    func testXorDifferentLengthsThrows() {
        let a = Data([0x01, 0x02])
        let b = Data([0x01])
        XCTAssertThrowsError(try a.xor(with: b))
    }

    // MARK: - HMAC-SHA256

    func testHmacSHA256() {
        // RFC 4231 Test Case 2
        let key = Data("Jefe".utf8)
        let data = Data("what do ya want for nothing?".utf8)
        let hmac = key.hmacSHA256(input: data)
        XCTAssertEqual(hmac.hexString, "5BDCC146BF60754E6A042426089575C75A003F089D2739839DEC58B964EC3843")
    }

    // MARK: - PBKDF2

    func testPbkdf2sha256() throws {
        let password = Data("password".utf8)
        let salt = Data("salt".utf8)
        let derived = try password.pbkdf2sha256(salt: salt, rounds: 1)
        XCTAssertEqual(derived.count, 32)
        // Deterministic: same input → same output
        let derived2 = try password.pbkdf2sha256(salt: salt, rounds: 1)
        XCTAssertEqual(derived, derived2)
    }

    func testPbkdf2sha512() throws {
        let password = Data("password".utf8)
        let salt = Data("salt".utf8)
        let derived = try password.pbkdf2sha512(salt: salt, rounds: 1)
        XCTAssertEqual(derived.count, 64)
    }

    // MARK: - AES-CBC encrypt/decrypt

    func testAESCBCRoundTrip() throws {
        let key = Data(hexString: "000102030405060708090A0B0C0D0E0F000102030405060708090A0B0C0D0E0F")
        let plaintext = Data("Hello, World! This is a test.".utf8)
        let encrypted = try plaintext.encrypt(with: key)
        XCTAssertNotEqual(encrypted, plaintext)
        let decrypted = try encrypted.decrypt(with: key)
        XCTAssertEqual(decrypted, plaintext)
    }

    // MARK: - Hex string edge cases

    func testHexStringInitWithInvalidCharacters() {
        let data = Data(hexString: "ZZZZ")
        XCTAssertTrue(data.isEmpty)
    }

    func testHexStringInitOddLength() {
        // Odd-length hex: last nibble appended as-is
        let data = Data(hexString: "ABC")
        XCTAssertEqual(data.count, 2)
        XCTAssertEqual(data, Data([0xAB, 0x0C]))
    }

    func testHexStringInitEmpty() {
        let data = Data(hexString: "")
        XCTAssertTrue(data.isEmpty)
    }

    // MARK: - Data(byte) init

    func testSingleByteInit() {
        let data = Data(0xFF)
        XCTAssertEqual(data, Data([0xFF]))
        XCTAssertEqual(data.count, 1)
    }

    // MARK: - utf8String

    func testUtf8StringWithoutNull() {
        let data = Data("hello".utf8)
        XCTAssertEqual(data.utf8String, "hello")
    }

    func testUtf8StringNilForInvalidUTF8() {
        // 0xFE is not valid in UTF-8 sequences
        let data = Data([0xFE, 0xFE])
        XCTAssertNil(data.utf8String)
    }

    // MARK: - toDate edge cases

    func testToDateNilForShortData() {
        let data = Data([0x07, 0xE2, 0x07])
        XCTAssertNil(data.toDate())
    }

    func testToDateExactly4Bytes() {
        let data = Data(hexString: "07E2071B") // 2018-07-27
        let date = data.toDate()
        XCTAssertNotNil(date)
    }
}
