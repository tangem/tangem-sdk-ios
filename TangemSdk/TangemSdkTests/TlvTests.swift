//
//  TlvTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 13.11.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import CoreNFC
@testable import TangemSdk

class TlvTests: XCTestCase {
    func testTlvSerialization() {
        let testData = Data(hexString: "0105000000000050020101")
        let tlv1 = Tlv(TlvTag.cardId, value: Data(repeating: UInt8(0), count: 5))
        let tlv2 = Tlv(tagRaw: Byte(0x50), value: Data(repeating: UInt8(1), count: 2))
        let tlvArray = [tlv1, tlv2]
        let serialized = tlvArray.serialize()
        XCTAssertEqual(serialized, testData)
        
        let tlv3 = Tlv(tagRaw: 0x69, value: Data())
        XCTAssertEqual(tlv3.tag, TlvTag.unknown)
        
        let tlvLong = Tlv(.cardPublicKey, value: Data(repeating: UInt8(0), count: 255))
        let tlvLongData = tlvLong.serialize()
        XCTAssertEqual(tlvLongData.count, 259)
    }
    
    func testTlvDeserialization() {
        let testData = Data(hexString: "010500000000005002010110FF000A00000000000000000000")
        let deserialized = Tlv.deserialize(testData)
        XCTAssertNotNil(deserialized)
        
        let tlv1 = Tlv(TlvTag.cardId, value: Data(repeating: UInt8(0), count: 5))
        let tlv2 = Tlv(tagRaw: Byte(0x50), value: Data(repeating: UInt8(1), count: 2))
        let tlv3 = Tlv(.pin, value: Data(repeating: UInt8(0), count: 10))
        let tlvArray = [tlv1, tlv2, tlv3]
        
        XCTAssertTrue(deserialized!.contains(tag: .cardId))
        XCTAssertEqual(deserialized!, tlvArray)
        
        XCTAssertNotNil(Tlv.deserialize(Data()))
        
        let testBadData = Data(hexString: "10FF000A000000")
        XCTAssertNil(Tlv.deserialize(testBadData))
        
        let testBadData1 = Data(hexString: "10FF00")
        XCTAssertNil(Tlv.deserialize(testBadData1))
        
        let testBadData2 = Data(hexString: "10")
        XCTAssertNil(Tlv.deserialize(testBadData2))
        
        XCTAssertNotNil(Tlv.deserialize( Data(hexString: "1000")))
    }
    
    func testMapping() {
        let testData = Data(hexString: "0108FF00000000000111200B534D415254204341534800020102800A312E3238642053444B000341044CB1004B43B407419E29A8FFDB64D4E54B623CEB37F3C2037B3ED6F38EEE0C1F2E5AB5D015DF78FE15EFA5327F59A24C059C999AFC1D3F2A8DDEEE16467CA75F0A027E310C5E8102FFFF820407E2071B830B54414E47454D2053444B00840342544386405D7FFCE7446DAA9084595F383E712A63B2AC4CF7BDE7673F05D6FC629F0D3E0F637910B5A675F66B633331630AEFB614345AF05208DEECF2274FF3B44642AC883041045F16BD1D2EAFE463E62A335A09E6B2BBCBD04452526885CB679FC4D27AF1BD22F553C7DEEFB54FD3D4F361D14E6DC3F11B7D4EA183250A60720EBDF9E110CD26050A736563703235366B3100080400000064070100090205DC604104B45FF0D628E1B59F7AEFA1D5B45AB9D7C47FC090D8B29ACCB515431BDBAD2802DDB3AC5E83A06BD8F13ABB84A465CA3C0FA0B44301F80295A9B4C5E35D5FDFE56204000000646304000000000F01009000")
        
        let tlv = Tlv.deserialize(testData)!
        let mapper = TlvMapper(tlv: tlv)
        
        //test map to optional
        let optinalHexString: String? = try? mapper.map(.cardId)
        XCTAssertNotNil(optinalHexString)
        
        //test map
        let hexString: String = try! mapper.map(.cardId)
        XCTAssertEqual(hexString, "FF00000000000111")
        
        let hexStringWrongType: Data? = try? mapper.map(.cardId)
        XCTAssertNil(hexStringWrongType)
        
        //test map optional parameter to optional
        let optionalParameter: String? = try! mapper.mapOptional(.manufacturerName)
        XCTAssertNotNil(optionalParameter)
        
        //test missing optional
        let missing: String? = try! mapper.mapOptional(.tokenSymbol)
        XCTAssertNil(missing)
        
        //test missing not optional
        do {
            let _: String = try mapper.map(.blockchainName)
            XCTAssertTrue(false)
        } catch {
            XCTAssertTrue(true)
        }
        
        //test wrong type
        do {
            let _: String = try mapper.map(.isActivated)
            XCTAssertTrue(false)
        } catch {
            XCTAssertTrue(true)
        }
        
        do {
            let _: String? = try mapper.mapOptional(.isActivated)
            XCTAssertTrue(false)
        } catch {
            XCTAssertTrue(true)
        }
        
        //test false bool
        let falseBool: Bool = try! mapper.map(.isLinked)
        XCTAssertFalse(falseBool)
        
        //test utf8String
        let utf8String: String = try! mapper.map(.manufacturerName)
        XCTAssertEqual(utf8String, "SMART CASH")
        
        let utf8StringWrongType: Data? = try? mapper.map(.manufacturerName)
        XCTAssertNil(utf8StringWrongType)
        
        //test int
        let maxSignatures: Int = try! mapper.map(.maxSignatures)
        XCTAssertEqual(maxSignatures, 100)
        
        let maxSignaturesWrong: String? = try? mapper.map(.maxSignatures)
        XCTAssertNil(maxSignaturesWrong)
        
        //test data
        let walletPublicKey: Data = try! mapper.map(.walletPublicKey)
        XCTAssertEqual(walletPublicKey, Data(hexString:"04B45FF0D628E1B59F7AEFA1D5B45AB9D7C47FC090D8B29ACCB515431BDBAD2802DDB3AC5E83A06BD8F13ABB84A465CA3C0FA0B44301F80295A9B4C5E35D5FDFE5"))
        
        let walletPublicKeyWrong: String? = try? mapper.map(.walletPublicKey)
        XCTAssertNil(walletPublicKeyWrong)
        
        //test curve
        let curve: EllipticCurve = try! mapper.map(.curveId)
        XCTAssertEqual(curve, EllipticCurve.secp256k1)
        
        let curveWrong: String? = try? mapper.map(.curveId)
        XCTAssertNil(curveWrong)
        
        //test settings mask
        let settings: SettingsMask = try! mapper.map(.settingsMask)
        XCTAssertEqual(settings, SettingsMask(rawValue: 32305))
        XCTAssertTrue(settings.contains(.isReusable))
        XCTAssertTrue(settings.contains(.allowSetPIN2))
        XCTAssertTrue(!settings.contains(.checkPIN3OnCard))
        XCTAssertTrue(!settings.contains(.useOneCommandAtTime))
        
        let settingsWrong: Bool? = try? mapper.map(.settingsMask)
        XCTAssertNil(settingsWrong)
        
        //card status
        let status: CardStatus = try! mapper.map(.status)
        XCTAssertEqual(status, CardStatus.loaded)
        
        let statusWrong: String? = try? mapper.map(.status)
        XCTAssertNil(statusWrong)
        //signing method
        let method: SigningMethod = try! mapper.map(.signingMethod)
        XCTAssertTrue(method.contains(.signHash))
        XCTAssertFalse(method.contains(.signRawSignedByIssuer))
        
        let methodWrong: String? = try? mapper.map(.signingMethod)
        XCTAssertNil(methodWrong)
        
        let someMethods: SigningMethod = Data(hexString: "070195").mapTlv(tag: .signingMethod)!
        XCTAssertTrue(someMethods.contains(.signHash))
        XCTAssertFalse(someMethods.contains(.signRaw))
        XCTAssertFalse(someMethods.contains(.signRawSignedByIssuer))
        XCTAssertTrue(someMethods.contains(.signHashSignedByIssuer))
        XCTAssertTrue(someMethods.contains(.signHashSignedByIssuerAndUpdateIssuerData))
        XCTAssertFalse(someMethods.contains(.signRawSignedByIssuerAndUpdateIssuerData))
        XCTAssertFalse(someMethods.contains(.signPos))
        
        //get cardData
        let cardData = tlv.value(for: .cardData)!
        let cardDataTlv = Tlv.deserialize(cardData)!
        let cardDataMapper = TlvMapper(tlv: cardDataTlv)
        
        //test dateTime
        let date: Date = try! cardDataMapper.map(.manufactureDateTime)
        let dateString =  date.toString(style: .short)
        XCTAssertEqual(dateString, "7/27/18")
        
        let dateWrong: Int? = try? cardDataMapper.map(.manufactureDateTime)
        XCTAssertNil(dateWrong)
        
        //test productMask
        let productMask: ProductMask = Data(hexString: "8A0102").mapTlv(tag: .productMask)!
        XCTAssertEqual(productMask, ProductMask.tag)
        
        let productMaskWrong: String? = Data(hexString: "8A0102").mapTlv(tag: .productMask)
        XCTAssertNil(productMaskWrong)
        
        //test byte
        let testByte: Int = Data(hexString: "510109").mapTlv(tag: .transactionOutHashSize)!
        XCTAssertEqual(testByte, Int(9))
        
        let testByteWrong: String? = Data(hexString: "510109").mapTlv(tag: .transactionOutHashSize)
        XCTAssertNil(testByteWrong)
    }
    
    func testEncode() {
        XCTAssertEqual(try! TlvBuilder().append(.cardId, value: "FF00000000000111").serialize(), Data(hexString: "0108FF00000000000111"))
        XCTAssertEqual(try! TlvBuilder().append(.manufacturerName, value: "SMART CASH").serialize(), Data(hexString: "200B534D415254204341534800"))
        XCTAssertEqual(try! TlvBuilder().append(.maxSignatures, value: 100).serialize(), Data(hexString: "080400000064"))
        
        XCTAssertEqual(try! TlvBuilder().append(.walletPublicKey, value: Data(hexString:"04B45FF0D628E1B59F7AEFA1D5B45AB9D7C47FC090D8B29ACCB515431BDBAD2802DDB3AC5E83A06BD8F13ABB84A465CA3C0FA0B44301F80295A9B4C5E35D5FDFE5")).serialize(), Data(hexString:
            "604104B45FF0D628E1B59F7AEFA1D5B45AB9D7C47FC090D8B29ACCB515431BDBAD2802DDB3AC5E83A06BD8F13ABB84A465CA3C0FA0B44301F80295A9B4C5E35D5FDFE5"))
        
        XCTAssertEqual(try! TlvBuilder().append(.curveId, value: EllipticCurve.secp256k1).serialize(), Data(hexString: "050A736563703235366B3100"))
        XCTAssertEqual(try! TlvBuilder().append(.settingsMask, value: SettingsMask(rawValue: 32305)).serialize(), Data(hexString: "0A027E31"))
        XCTAssertEqual(try! TlvBuilder().append(.settingsMask, value: SettingsMask(rawValue: 32305)).serialize(), Data(hexString: "0A027E31"))
        XCTAssertEqual(try! TlvBuilder().append(.status, value: CardStatus.loaded).serialize(), Data(hexString: "020102"))
        XCTAssertEqual(try! TlvBuilder().append(.signingMethod, value: SigningMethod.signHash).serialize(), Data(hexString: "070181"))

        let date = Date(timeIntervalSince1970: 1532696400)
        XCTAssertEqual(try! TlvBuilder().append(.manufactureDateTime, value: date).serialize(), Data(hexString: "820407E2071B"))
        
        XCTAssertEqual(try! TlvBuilder().append(.productMask, value: ProductMask.tag).serialize(), Data(hexString: "8A0102"))
        XCTAssertEqual(try! TlvBuilder().append(.transactionOutHashSize, value:9).serialize(), Data(hexString: "510109"))
        XCTAssertEqual(try! TlvBuilder().append(.pin, value: "12345").serialize(), Data(hexString: "10205994471abb01112afcc18159f6cc74b4f511b99806da59b3caf5a9c173cacfc5"))
    }
}
