//
//  SLIP10Tests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 01.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import CryptoKit
@testable import TangemSdk

/// Firmware 6.31
/// test vectors for secp356k1 are equal to BIP32 test vectors
@available(iOS 13.0, *)
class SLIP10Tests: XCTestCase {

    // MARK: - Test vector 1 for nist256p1

    /// Chain m
    @available(iOS 16.0, *)
    func testVector11Secp256r1() throws {
        let seed = Data(hexString: "000102030405060708090a0b0c0d0e0f")
        let bip32 = BIP32()

        let mPrv = try bip32.makeMasterKey(from: seed, curve: .secp256r1)
        let mPub = (try P256.Signing.PrivateKey(rawRepresentation: mPrv.privateKey)).publicKey.compressedRepresentation

        XCTAssertEqual(mPrv.privateKey.hexString.lowercased(), "612091aaa12e22dd2abef664f8a01a82cae99ad7441b7ef8110424915c268bc2")
        XCTAssertEqual(mPrv.chainCode.hexString.lowercased(), "beeb672fe4621673f722f38529c07392fecaa61015c80c34f29ce8b41b3cb6ea")
        XCTAssertEqual(mPub.hexString.lowercased(), "0266874dc6ade47b3ecd096745ca09bcd29638dd52c2c12117b11ed3e458cfa9e8")

        // compare with card's master key
        XCTAssertEqual(mPub.hexString, "0266874DC6ADE47B3ECD096745CA09BCD29638DD52C2C12117B11ED3E458CFA9E8")
    }

    /// Chain m/0H ext pub
    func testVector12Secp256r1() throws {
        let expectedPub = "0384610f5ecffe8fda089363a41f56a5c7ffc1d81b59a612d0d649b2d22355590c"
        let expectedChainCode = "3460cea53e6a6bb5fb391eeef3237ffd8724bf0a40e94943c98b83825342ee11"

        XCTAssertEqual(expectedPub.uppercased(), "0384610F5ECFFE8FDA089363A41F56A5C7FFC1D81B59A612D0D649B2D22355590C")
        XCTAssertEqual(expectedChainCode.uppercased(), "3460CEA53E6A6BB5FB391EEEF3237FFD8724BF0A40E94943C98B83825342EE11")
    }

    /// Chain m/0H/1 ext pub
    func testVector13Secp256r1() throws {
        let expectedPub = "03526c63f8d0b4bbbf9c80df553fe66742df4676b241dabefdef67733e070f6844"
        let expectedChainCode = "4187afff1aafa8445010097fb99d23aee9f599450c7bd140b6826ac22ba21d0c"

        XCTAssertEqual(expectedPub.uppercased(), "03526C63F8D0B4BBBF9C80DF553FE66742DF4676B241DABEFDEF67733E070F6844")
        XCTAssertEqual(expectedChainCode.uppercased(), "4187AFFF1AAFA8445010097FB99D23AEE9F599450C7BD140B6826AC22BA21D0C")
    }

    /// Chain m/0H/1/2H ext pub
    func testVector14Secp256r1() throws {
        let expectedPub = "0359cf160040778a4b14c5f4d7b76e327ccc8c4a6086dd9451b7482b5a4972dda0"
        let expectedChainCode = "98c7514f562e64e74170cc3cf304ee1ce54d6b6da4f880f313e8204c2a185318"

        XCTAssertEqual(expectedPub.uppercased(), "0359CF160040778A4B14C5F4D7B76E327CCC8C4A6086DD9451B7482B5A4972DDA0")
        XCTAssertEqual(expectedChainCode.uppercased(), "98C7514F562E64E74170CC3CF304EE1CE54D6B6DA4F880F313E8204C2A185318")
    }

    /// Chain m/0H/1/2H/2 ext pub
    func testVector15Secp256r1() throws {
        let expectedPub = "029f871f4cb9e1c97f9f4de9ccd0d4a2f2a171110c61178f84430062230833ff20"
        let expectedChainCode = "ba96f776a5c3907d7fd48bde5620ee374d4acfd540378476019eab70790c63a0"

        XCTAssertEqual(expectedPub.uppercased(), "029F871F4CB9E1C97F9F4DE9CCD0D4A2F2A171110C61178F84430062230833FF20")
        XCTAssertEqual(expectedChainCode.uppercased(), "BA96F776A5C3907D7FD48BDE5620EE374D4ACFD540378476019EAB70790C63A0")
    }

    /// Chain m/0H/1/2H/2/1000000000
    func testVector16Secp256r1() throws {
        let expectedPub = "02216cd26d31147f72427a453c443ed2cde8a1e53c9cc44e5ddf739725413fe3f4"
        let expectedChainCode = "b9b7b82d326bb9cb5b5b121066feea4eb93d5241103c9e7a18aad40f1dde8059"

        XCTAssertEqual(expectedPub.uppercased(), "02216CD26D31147F72427A453C443ED2CDE8A1E53C9CC44E5DDF739725413FE3F4")
        XCTAssertEqual(expectedChainCode.uppercased(), "B9B7B82D326BB9CB5B5B121066FEEA4EB93D5241103C9E7A18AAD40F1DDE8059")
    }

    // MARK: Test vector 1 for ed25519_slip0010

    /// Chain m
    func testVector11ed25519() throws {
        let seed = Data(hexString: "000102030405060708090a0b0c0d0e0f")
        let bip32 = BIP32()

        let mPrv = try bip32.makeMasterKey(from: seed, curve: .ed25519slip0010)
        let mPub = try mPrv.makePublicKey(for: .ed25519slip0010)

        XCTAssertEqual(mPrv.privateKey.hexString.lowercased(), "2b4be7f19ee27bbf30c667b642d5f4aa69fd169872f8fc3059c08ebae2eb19e7")
        XCTAssertEqual(mPrv.chainCode.hexString.lowercased(), "90046a93de5380a72b5e45010748567d5ea02bbf6522f979e05c0d8d8ca9fffb")
        XCTAssertEqual(mPub.publicKey.hexString.lowercased(), "00a4b2856bfec510abab89753fac1ac0e1112364e7d250545963f135f2a33188ed")

        // compare with card's master key
        XCTAssertEqual(mPub.publicKey.hexString, "A4B2856BFEC510ABAB89753FAC1AC0E1112364E7D250545963F135F2A33188ED")
    }

    /// Chain m/0H
    func testVector12ed25519() throws {
        let expectedPub = "008c8a13df77a28f3445213a0f432fde644acaa215fc72dcdf300d5efaa85d350c"
        let expectedChainCode = "8b59aa11380b624e81507a27fedda59fea6d0b779a778918a2fd3590e16e9c69"

        XCTAssertEqual(expectedPub.uppercased(), "8C8A13DF77A28F3445213A0F432FDE644ACAA215FC72DCDF300D5EFAA85D350C")
        XCTAssertEqual(expectedChainCode.uppercased(), "8B59AA11380B624E81507A27FEDDA59FEA6D0B779A778918A2FD3590E16E9C69")
    }

    /// Chain m/0H/1H
    func testVector13ed25519() throws {
        let expectedPub = "001932a5270f335bed617d5b935c80aedb1a35bd9fc1e31acafd5372c30f5c1187"
        let expectedChainCode = "a320425f77d1b5c2505a6b1b27382b37368ee640e3557c315416801243552f14"

        XCTAssertEqual(expectedPub.uppercased(), "1932A5270F335BED617D5B935C80AEDB1A35BD9FC1E31ACAFD5372C30F5C1187")
        XCTAssertEqual(expectedChainCode.uppercased(), "A320425F77D1B5C2505A6B1B27382B37368EE640E3557C315416801243552F14")
    }

    /// Chain m/0H/1H/2H
    func testVector14ed25519() throws {
        let expectedPub = "00ae98736566d30ed0e9d2f4486a64bc95740d89c7db33f52121f8ea8f76ff0fc1"
        let expectedChainCode = "2e69929e00b5ab250f49c3fb1c12f252de4fed2c1db88387094a0f8c4c9ccd6c"

        XCTAssertEqual(expectedPub.uppercased(), "AE98736566D30ED0E9D2F4486A64BC95740D89C7DB33F52121F8EA8F76FF0FC1")
        XCTAssertEqual(expectedChainCode.uppercased(), "2E69929E00B5AB250F49C3FB1C12F252DE4FED2C1DB88387094A0F8C4C9CCD6C")
    }

    /// Chain m/0H/1H/2H/2H
    func testVector15ed25519() throws {
        let expectedPub = "008abae2d66361c879b900d204ad2cc4984fa2aa344dd7ddc46007329ac76c429c"
        let expectedChainCode = "8f6d87f93d750e0efccda017d662a1b31a266e4a6f5993b15f5c1f07f74dd5cc"

        XCTAssertEqual(expectedPub.uppercased(), "8ABAE2D66361C879B900D204AD2CC4984FA2AA344DD7DDC46007329AC76C429C")
        XCTAssertEqual(expectedChainCode.uppercased(), "8F6D87F93D750E0EFCCDA017D662A1B31A266E4A6F5993B15F5C1F07F74DD5CC")
    }

    /// Chain m/0H/1H/2H/2H/1000000000H
    func testVector16ed25519() throws {
        let expectedPub = "003c24da049451555d51a7014a37337aa4e12d41e485abccfa46b47dfb2af54b7a"
        let expectedChainCode = "68789923a0cac2cd5a29172a475fe9e0fb14cd6adb5ad98a3fa70333e7afa230"

        XCTAssertEqual(expectedPub.uppercased(), "3C24DA049451555D51A7014A37337AA4E12D41E485ABCCFA46B47DFB2AF54B7A")
        XCTAssertEqual(expectedChainCode.uppercased(), "68789923A0CAC2CD5A29172A475FE9E0FB14CD6ADB5AD98A3FA70333E7AFA230")
    }

    // MARK: - Test vector 2 for nist256p1

    /// Chain m
    @available(iOS 16.0, *)
    func testVector21Secp256r1() throws {
        let seed = Data(hexString: "fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542")
        let bip32 = BIP32()

        let mPrv = try bip32.makeMasterKey(from: seed, curve: .secp256r1)
        let mPub = (try P256.Signing.PrivateKey(rawRepresentation: mPrv.privateKey)).publicKey.compressedRepresentation

        XCTAssertEqual(mPrv.privateKey.hexString.lowercased(), "eaa31c2e46ca2962227cf21d73a7ef0ce8b31c756897521eb6c7b39796633357")
        XCTAssertEqual(mPrv.chainCode.hexString.lowercased(), "96cd4465a9644e31528eda3592aa35eb39a9527769ce1855beafc1b81055e75d")
        XCTAssertEqual(mPub.hexString.lowercased(), "02c9e16154474b3ed5b38218bb0463e008f89ee03e62d22fdcc8014beab25b48fa")

        // compare with card's master key
        XCTAssertEqual(mPub.hexString, "02C9E16154474B3ED5B38218BB0463E008F89EE03E62D22FDCC8014BEAB25B48FA")
    }

    /// Chain m/0 ext pub
    func testVector22Secp256r1() throws {
        let expectedPub = "039b6df4bece7b6c81e2adfeea4bcf5c8c8a6e40ea7ffa3cf6e8494c61a1fc82cc"
        let expectedChainCode = "84e9c258bb8557a40e0d041115b376dd55eda99c0042ce29e81ebe4efed9b86a"

        XCTAssertEqual(expectedPub.uppercased(), "039B6DF4BECE7B6C81E2ADFEEA4BCF5C8C8A6E40EA7FFA3CF6E8494C61A1FC82CC")
        XCTAssertEqual(expectedChainCode.uppercased(), "84E9C258BB8557A40E0D041115B376DD55EDA99C0042CE29E81EBE4EFED9B86A")
    }

    /// Chain m/0/2147483647H ext pub
    func testVector23Secp256r1() throws {
        let expectedPub = "02f89c5deb1cae4fedc9905f98ae6cbf6cbab120d8cb85d5bd9a91a72f4c068c76"
        let expectedChainCode = "f235b2bc5c04606ca9c30027a84f353acf4e4683edbd11f635d0dcc1cd106ea6"

        XCTAssertEqual(expectedPub.uppercased(), "02F89C5DEB1CAE4FEDC9905F98AE6CBF6CBAB120D8CB85D5BD9A91A72F4C068C76")
        XCTAssertEqual(expectedChainCode.uppercased(), "F235B2BC5C04606CA9C30027A84F353ACF4E4683EDBD11F635D0DCC1CD106EA6")
    }

    /// Chain m/0/2147483647H/1 ext pub
    func testVector24Secp256r1() throws {
        let expectedPub = "03abe0ad54c97c1d654c1852dfdc32d6d3e487e75fa16f0fd6304b9ceae4220c64"
        let expectedChainCode = "7c0b833106235e452eba79d2bdd58d4086e663bc8cc55e9773d2b5eeda313f3b"

        XCTAssertEqual(expectedPub.uppercased(), "03ABE0AD54C97C1D654C1852DFDC32D6D3E487E75FA16F0FD6304B9CEAE4220C64")
        XCTAssertEqual(expectedChainCode.uppercased(), "7C0B833106235E452EBA79D2BDD58D4086E663BC8CC55E9773D2B5EEDA313F3B")
    }

    /// Chain m/0/2147483647H/1/2147483646H ext pub
    func testVector25Secp256r1() throws {
        let expectedPub = "03cb8cb067d248691808cd6b5a5a06b48e34ebac4d965cba33e6dc46fe13d9b933"
        let expectedChainCode = "5794e616eadaf33413aa309318a26ee0fd5163b70466de7a4512fd4b1a5c9e6a"

        XCTAssertEqual(expectedPub.uppercased(), "03CB8CB067D248691808CD6B5A5A06B48E34EBAC4D965CBA33E6DC46FE13D9B933")
        XCTAssertEqual(expectedChainCode.uppercased(), "5794E616EADAF33413AA309318A26EE0FD5163B70466DE7A4512FD4B1A5C9E6A")
    }

    /// Chain m/0/2147483647H/1/2147483646H/2
    func testVector26Secp256r1() throws {
        let expectedPub = "020ee02e18967237cf62672983b253ee62fa4dd431f8243bfeccdf39dbe181387f"
        let expectedChainCode = "3bfb29ee8ac4484f09db09c2079b520ea5616df7820f071a20320366fbe226a7"

        XCTAssertEqual(expectedPub.uppercased(), "020EE02E18967237CF62672983B253EE62FA4DD431F8243BFECCDF39DBE181387F")
        XCTAssertEqual(expectedChainCode.uppercased(), "3BFB29EE8AC4484F09DB09C2079B520EA5616DF7820F071A20320366FBE226A7")
    }

    // MARK: Test vector 2 for ed25519_slip0010

    /// Chain m
    func testVector21ed25519() throws {
        let seed = Data(hexString: "fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542")
        let bip32 = BIP32()

        let mPrv = try bip32.makeMasterKey(from: seed, curve: .ed25519slip0010)
        let mPub = try mPrv.makePublicKey(for: .ed25519slip0010)

        XCTAssertEqual(mPrv.privateKey.hexString.lowercased(), "171cb88b1b3c1db25add599712e36245d75bc65a1a5c9e18d76f9f2b1eab4012")
        XCTAssertEqual(mPrv.chainCode.hexString.lowercased(), "ef70a74db9c3a5af931b5fe73ed8e1a53464133654fd55e7a66f8570b8e33c3b")
        XCTAssertEqual(mPub.publicKey.hexString.lowercased(), "008fe9693f8fa62a4305a140b9764c5ee01e455963744fe18204b4fb948249308a")

        // compare with card's master key
        XCTAssertEqual(mPub.publicKey.hexString, "8FE9693F8FA62A4305A140B9764C5EE01E455963744FE18204B4FB948249308A")
    }

    /// Chain m/0H
    func testVector22ed25519() throws {
        let expectedPub = "0086fab68dcb57aa196c77c5f264f215a112c22a912c10d123b0d03c3c28ef1037"
        let expectedChainCode = "0b78a3226f915c082bf118f83618a618ab6dec793752624cbeb622acb562862d"

        XCTAssertEqual(expectedPub.uppercased(), "86FAB68DCB57AA196C77C5F264F215A112C22A912C10D123B0D03C3C28EF1037")
        XCTAssertEqual(expectedChainCode.uppercased(), "0B78A3226F915C082BF118F83618A618AB6DEC793752624CBEB622ACB562862D")
    }

    /// Chain m/0H/2147483647H
    func testVector23ed25519() throws {
        let expectedPub = "005ba3b9ac6e90e83effcd25ac4e58a1365a9e35a3d3ae5eb07b9e4d90bcf7506d"
        let expectedChainCode = "138f0b2551bcafeca6ff2aa88ba8ed0ed8de070841f0c4ef0165df8181eaad7f"

        XCTAssertEqual(expectedPub.uppercased(), "5BA3B9AC6E90E83EFFCD25AC4E58A1365A9E35A3D3AE5EB07B9E4D90BCF7506D")
        XCTAssertEqual(expectedChainCode.uppercased(), "138F0B2551BCAFECA6FF2AA88BA8ED0ED8DE070841F0C4EF0165DF8181EAAD7F")
    }

    /// Chain m/0H/2147483647H/1H
    func testVector24ed25519() throws {
        let expectedPub = "002e66aa57069c86cc18249aecf5cb5a9cebbfd6fadeab056254763874a9352b45"
        let expectedChainCode = "73bd9fff1cfbde33a1b846c27085f711c0fe2d66fd32e139d3ebc28e5a4a6b90"

        XCTAssertEqual(expectedPub.uppercased(), "2E66AA57069C86CC18249AECF5CB5A9CEBBFD6FADEAB056254763874A9352B45")
        XCTAssertEqual(expectedChainCode.uppercased(), "73BD9FFF1CFBDE33A1B846C27085F711C0FE2D66FD32E139D3EBC28E5A4A6B90")
    }

    /// Chain m/0H/2147483647H/1H/2147483646H
    func testVector25ed25519() throws {
        let expectedPub = "00e33c0f7d81d843c572275f287498e8d408654fdf0d1e065b84e2e6f157aab09b"
        let expectedChainCode = "0902fe8a29f9140480a00ef244bd183e8a13288e4412d8389d140aac1794825a"

        XCTAssertEqual(expectedPub.uppercased(), "E33C0F7D81D843C572275F287498E8D408654FDF0D1E065B84E2E6F157AAB09B")
        XCTAssertEqual(expectedChainCode.uppercased(), "0902FE8A29F9140480A00EF244BD183E8A13288E4412D8389D140AAC1794825A")
    }

    /// Chain m/0H/2147483647H/1H/2147483646H/2H
    func testVector26ed25519() throws {
        let expectedPub = "0047150c75db263559a70d5778bf36abbab30fb061ad69f69ece61a72b0cfa4fc0"
        let expectedChainCode = "5d70af781f3a37b829f0d060924d5e960bdc02e85423494afc0b1a41bbe196d4"

        XCTAssertEqual(expectedPub.uppercased(), "47150C75DB263559A70D5778BF36ABBAB30FB061AD69F69ECE61A72B0CFA4FC0")
        XCTAssertEqual(expectedChainCode.uppercased(), "5D70AF781F3A37B829F0D060924D5E960BDC02E85423494AFC0B1A41BBE196D4")
    }

    // MARK: - Test derivation retry for nist256p1

    func testSecp256r1DerivationRetry() throws {
        let bip32 = BIP32()
        let masterKey = try bip32.makeMasterKey(from: Data(hexString: "000102030405060708090a0b0c0d0e0f"), curve: .secp256r1)
        XCTAssertEqual(masterKey.privateKey.hexString.lowercased(), "612091aaa12e22dd2abef664f8a01a82cae99ad7441b7ef8110424915c268bc2".lowercased())
        XCTAssertEqual(masterKey.chainCode.hexString.lowercased(), "beeb672fe4621673f722f38529c07392fecaa61015c80c34f29ce8b41b3cb6ea".lowercased())

        // verify with card
        let expectedMasterPublic = "0266874dc6ade47b3ecd096745ca09bcd29638dd52c2c12117b11ed3e458cfa9e8"
        XCTAssertEqual(expectedMasterPublic.uppercased(), "0266874DC6ADE47B3ECD096745CA09BCD29638DD52C2C12117B11ED3E458CFA9E8")

        // Chain m/28578H
        let expectedChainCode = "e94c8ebe30c2250a14713212f6449b20f3329105ea15b652ca5bdfc68f6c65c2"
        let expectedPublic = "02519b5554a4872e8c9c1c847115363051ec43e93400e030ba3c36b52a3e70a5b7"

        // verify with card
        XCTAssertEqual(expectedPublic.uppercased(), "02519B5554A4872E8C9C1C847115363051EC43E93400E030BA3C36B52A3E70A5B7")
        XCTAssertEqual(expectedChainCode.uppercased(), "E94C8EBE30C2250A14713212F6449B20F3329105EA15B652CA5BDFC68F6C65C2")

        // Chain m/28578H/33941

        let expectedChainCode1 = "9e87fe95031f14736774cd82f25fd885065cb7c358c1edf813c72af535e83071"
        let expectedPublic1 = "0235bfee614c0d5b2cae260000bb1d0d84b270099ad790022c1ae0b2e782efe120"

        // verify with card
        XCTAssertEqual(expectedPublic1.uppercased(), "")
        XCTAssertEqual(expectedChainCode1.uppercased(), "")
    }

    // MARK: - Test seed retry for nist256p1

    func testSecp256r1MasterKeyGenerationRetry() throws {
        let bip32 = BIP32()
        let masterKey = try bip32.makeMasterKey(from: Data(hexString: "a7305bc8df8d0951f0cb224c0e95d7707cbdf2c6ce7e8d481fec69c7ff5e9446"), curve: .secp256r1)
        XCTAssertEqual(masterKey.privateKey.hexString.lowercased(), "3b8c18469a4634517d6d0b65448f8e6c62091b45540a1743c5846be55d47d88f".lowercased())
        XCTAssertEqual(masterKey.chainCode.hexString.lowercased(), "7762f9729fed06121fd13f326884c82f59aa95c57ac492ce8c9654e60efd130c".lowercased())
    }
}
