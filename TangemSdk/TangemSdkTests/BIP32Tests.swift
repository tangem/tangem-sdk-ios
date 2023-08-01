//
//  BIP32Tests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 07.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import CryptoKit
@testable import TangemSdk

/// 6.31 fw card used for derived keys
/// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#user-content-Test_Vectors
@available(iOS 13.0, *)
class BIP32Tests: XCTestCase {

    // MARK: - Test vector 1

    /// Chain m
    func testVector1Master() throws {
        let seed = Data(hexString: "000102030405060708090a0b0c0d0e0f")
        let bip32 = BIP32()

        let mPrv = try bip32.makeMasterKey(from: seed, curve: .secp256k1)
        let mPub = try mPrv.makePublicKey(for: .secp256k1)

        let xPrv = try mPrv.serialize(for: .mainnet)
        XCTAssertEqual(xPrv, "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi")

        let xPub = try mPub.serialize(for: .mainnet)
        XCTAssertEqual(xPub, "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8")

        // compare with card's master key
        XCTAssertEqual(mPub.publicKey.hexString, "0339A36013301597DAEF41FBE593A02CC513D0B55527EC2DF1050E2E8FF49C85C2")
    }

    /// Chain m/0H ext pub
    func testVector12() throws {
        let expected = try ExtendedPublicKey(from: "xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw", networkType: .mainnet)

        XCTAssertEqual(expected.publicKey.hexString, "035A784662A4A20A65BF6AAB9AE98A6C068A81C52E4B032C0FB5400C706CFCCC56")
        XCTAssertEqual(expected.chainCode.hexString, "47FDACBD0F1097043B78C63C20C34EF4ED9A111D980047AD16282C7AE6236141")
    }

    /// Chain m/0H/1 ext pub
    func testVector13() throws {
        let expected = try ExtendedPublicKey(from: "xpub6ASuArnXKPbfEwhqN6e3mwBcDTgzisQN1wXN9BJcM47sSikHjJf3UFHKkNAWbWMiGj7Wf5uMash7SyYq527Hqck2AxYysAA7xmALppuCkwQ", networkType: .mainnet)

        XCTAssertEqual(expected.publicKey.hexString, "03501E454BF00751F24B1B489AA925215D66AF2234E3891C3B21A52BEDB3CD711C")
        XCTAssertEqual(expected.chainCode.hexString, "2A7857631386BA23DACAC34180DD1983734E444FDBF774041578E9B6ADB37C19")
    }

    /// Chain m/0H/1/2H
    func testVector14() throws {
        let expected = try ExtendedPublicKey(from: "xpub6D4BDPcP2GT577Vvch3R8wDkScZWzQzMMUm3PWbmWvVJrZwQY4VUNgqFJPMM3No2dFDFGTsxxpG5uJh7n7epu4trkrX7x7DogT5Uv6fcLW5", networkType: .mainnet)

        XCTAssertEqual(expected.publicKey.hexString, "0357BFE1E341D01C69FE5654309956CBEA516822FBA8A601743A012A7896EE8DC2")
        XCTAssertEqual(expected.chainCode.hexString, "04466B9CC8E161E966409CA52986C584F07E9DC81F735DB683C3FF6EC7B1503F")
    }

    /// Chain m/0H/1/2H/2 ext pub
    func testVector15() throws {
        let expected = try ExtendedPublicKey(from: "xpub6FHa3pjLCk84BayeJxFW2SP4XRrFd1JYnxeLeU8EqN3vDfZmbqBqaGJAyiLjTAwm6ZLRQUMv1ZACTj37sR62cfN7fe5JnJ7dh8zL4fiyLHV", networkType: .mainnet)

        XCTAssertEqual(expected.publicKey.hexString, "02E8445082A72F29B75CA48748A914DF60622A609CACFCE8ED0E35804560741D29")
        XCTAssertEqual(expected.chainCode.hexString, "CFB71883F01676F587D023CC53A35BC7F88F724B1F8C2892AC1275AC822A3EDD")
    }

    /// Chain m/0H/1/2H/2/1000000000 ext pub
    func testVector16() throws {
        let expected = try ExtendedPublicKey(from: "xpub6H1LXWLaKsWFhvm6RVpEL9P4KfRZSW7abD2ttkWP3SSQvnyA8FSVqNTEcYFgJS2UaFcxupHiYkro49S8yGasTvXEYBVPamhGW6cFJodrTHy", networkType: .mainnet)

        XCTAssertEqual(expected.publicKey.hexString, "022A471424DA5E657499D1FF51CB43C47481A03B1E77F951FE64CEC9F5A48F7011")
        XCTAssertEqual(expected.chainCode.hexString, "C783E67B921D2BEB8F6B389CC646D7263B4145701DADD2161548A8B078E65E9E")
    }

    // MARK: - Test vector 2

    func testVector2Master() throws {
        let seed = Data(hexString: "fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542")
        let bip32 = BIP32()

        let mPrv = try bip32.makeMasterKey(from: seed, curve: .secp256k1)
        let mPub = try mPrv.makePublicKey(for: .secp256k1)

        let xPrv = try mPrv.serialize(for: .mainnet)
        XCTAssertEqual(xPrv, "xprv9s21ZrQH143K31xYSDQpPDxsXRTUcvj2iNHm5NUtrGiGG5e2DtALGdso3pGz6ssrdK4PFmM8NSpSBHNqPqm55Qn3LqFtT2emdEXVYsCzC2U")

        let xPub = try mPub.serialize(for: .mainnet)
        XCTAssertEqual(xPub, "xpub661MyMwAqRbcFW31YEwpkMuc5THy2PSt5bDMsktWQcFF8syAmRUapSCGu8ED9W6oDMSgv6Zz8idoc4a6mr8BDzTJY47LJhkJ8UB7WEGuduB")

        // compare with card's master key
        XCTAssertEqual(mPub.publicKey.hexString, "03CBCAA9C98C877A26977D00825C956A238E8DDDFBD322CCE4F74B0B5BD6ACE4A7")
    }

    /// Chain m/0 ext pub
    func testVector21() throws {
        let expected = try ExtendedPublicKey(from: "xpub69H7F5d8KSRgmmdJg2KhpAK8SR3DjMwAdkxj3ZuxV27CprR9LgpeyGmXUbC6wb7ERfvrnKZjXoUmmDznezpbZb7ap6r1D3tgFxHmwMkQTPH", networkType: .mainnet)

        XCTAssertEqual(expected.publicKey.hexString, "02FC9E5AF0AC8D9B3CECFE2A888E2117BA3D089D8585886C9C826B6B22A98D12EA")
        XCTAssertEqual(expected.chainCode.hexString, "F0909AFFAA7EE7ABE5DD4E100598D4DC53CD709D5A5C2CAC40E7412F232F7C9C")
    }

    /// Chain m/0/2147483647H ext pub
    func testVector22() throws {
        let expected = try ExtendedPublicKey(from: "xpub6ASAVgeehLbnwdqV6UKMHVzgqAG8Gr6riv3Fxxpj8ksbH9ebxaEyBLZ85ySDhKiLDBrQSARLq1uNRts8RuJiHjaDMBU4Zn9h8LZNnBC5y4a", networkType: .mainnet)

        XCTAssertEqual(expected.publicKey.hexString, "03C01E7425647BDEFA82B12D9BAD5E3E6865BEE0502694B94CA58B666ABC0A5C3B")
        XCTAssertEqual(expected.chainCode.hexString, "BE17A268474A6BB9C61E1D720CF6215E2A88C5406C4AEE7B38547F585C9A37D9")
    }

    /// Chain m/0/2147483647H/1 ext pub
    func testVector23() throws {
        let expected = try ExtendedPublicKey(from: "xpub6DF8uhdarytz3FWdA8TvFSvvAh8dP3283MY7p2V4SeE2wyWmG5mg5EwVvmdMVCQcoNJxGoWaU9DCWh89LojfZ537wTfunKau47EL2dhHKon", networkType: .mainnet)

        XCTAssertEqual(expected.publicKey.hexString, "03A7D1D856DEB74C508E05031F9895DAB54626251B3806E16B4BD12E781A7DF5B9")
        XCTAssertEqual(expected.chainCode.hexString, "F366F48F1EA9F2D1D3FE958C95CA84EA18E4C4DDB9366C336C927EB246FB38CB")
    }

    /// Chain m/0/2147483647H/1/2147483646H ext pub
    func testVector24() throws {
        let expected = try ExtendedPublicKey(from: "xpub6ERApfZwUNrhLCkDtcHTcxd75RbzS1ed54G1LkBUHQVHQKqhMkhgbmJbZRkrgZw4koxb5JaHWkY4ALHY2grBGRjaDMzQLcgJvLJuZZvRcEL", networkType: .mainnet)

        XCTAssertEqual(expected.publicKey.hexString, "02D2B36900396C9282FA14628566582F206A5DD0BCC8D5E892611806CAFB0301F0")
        XCTAssertEqual(expected.chainCode.hexString, "637807030D55D01F9A0CB3A7839515D796BD07706386A6EDDF06CC29A65A0E29")
    }

    /// Chain m/0/2147483647H/1/2147483646H/2 ext pub
    func testVector25() throws {
        let expected = try ExtendedPublicKey(from: "xpub6FnCn6nSzZAw5Tw7cgR9bi15UV96gLZhjDstkXXxvCLsUXBGXPdSnLFbdpq8p9HmGsApME5hQTZ3emM2rnY5agb9rXpVGyy3bdW6EEgAtqt", networkType: .mainnet)

        XCTAssertEqual(expected.publicKey.hexString, "024D902E1A2FC7A8755AB5B694C575FCE742C48D9FF192E63DF5193E4C7AFE1F9C")
        XCTAssertEqual(expected.chainCode.hexString, "9452B549BE8CEA3ECB7A84BEC10DCFD94AFE4D129EBFD3B3CB58EEDF394ED271")
    }

    // MARK: - Test vector 3

    func testVector3Master() throws {
        let seed = Data(hexString: "4b381541583be4423346c643850da4b320e46a87ae3d2a4e6da11eba819cd4acba45d239319ac14f863b8d5ab5a0d0c64d2e8a1e7d1457df2e5a3c51c73235be")
        let bip32 = BIP32()

        let mPriv = try bip32.makeMasterKey(from: seed, curve: .secp256k1)
        let mPub = try mPriv.makePublicKey(for: .secp256k1)

        let xpriv = try mPriv.serialize(for: .mainnet)
        XCTAssertEqual(xpriv, "xprv9s21ZrQH143K25QhxbucbDDuQ4naNntJRi4KUfWT7xo4EKsHt2QJDu7KXp1A3u7Bi1j8ph3EGsZ9Xvz9dGuVrtHHs7pXeTzjuxBrCmmhgC6")

        let xpub = try mPub.serialize(for: .mainnet)
        XCTAssertEqual(xpub, "xpub661MyMwAqRbcEZVB4dScxMAdx6d4nFc9nvyvH3v4gJL378CSRZiYmhRoP7mBy6gSPSCYk6SzXPTf3ND1cZAceL7SfJ1Z3GC8vBgp2epUt13")

        // compare with card's master key
        XCTAssertEqual(mPub.publicKey.hexString, "03683AF1BA5743BDFC798CF814EFEEAB2735EC52D95ECED528E692B8E34C4E5669")
    }

    /// m/0H ext pub
    func testVector31() throws {
        let expected = try ExtendedPublicKey(from: "xpub68NZiKmJWnxxS6aaHmn81bvJeTESw724CRDs6HbuccFQN9Ku14VQrADWgqbhhTHBaohPX4CjNLf9fq9MYo6oDaPPLPxSb7gwQN3ih19Zm4Y", networkType: .mainnet)

        XCTAssertEqual(expected.publicKey.hexString, "026557FDDA1D5D43D79611F784780471F086D58E8126B8C40ACB82272A7712E7F2")
        XCTAssertEqual(expected.chainCode.hexString, "E5FEA12A97B927FC9DC3D2CB0D1EA1CF50AA5A1FDC1F933E8906BB38DF3377BD")
    }

    // MARK: - Test vector 4

    func testVector4Master() throws {
        let seed = Data(hexString: "3ddd5602285899a946114506157c7997e5444528f3003f6134712147db19b678")
        let bip32 = BIP32()

        let mPriv = try bip32.makeMasterKey(from: seed, curve: .secp256k1)
        let mPub = try mPriv.makePublicKey(for: .secp256k1)

        let xpriv = try mPriv.serialize(for: .mainnet)
        XCTAssertEqual(xpriv, "xprv9s21ZrQH143K48vGoLGRPxgo2JNkJ3J3fqkirQC2zVdk5Dgd5w14S7fRDyHH4dWNHUgkvsvNDCkvAwcSHNAQwhwgNMgZhLtQC63zxwhQmRv")

        let xpub = try mPub.serialize(for: .mainnet)
        XCTAssertEqual(xpub, "xpub661MyMwAqRbcGczjuMoRm6dXaLDEhW1u34gKenbeYqAix21mdUKJyuyu5F1rzYGVxyL6tmgBUAEPrEz92mBXjByMRiJdba9wpnN37RLLAXa")

        // compare with card's master key
        XCTAssertEqual(mPub.publicKey.hexString, "026F6FEDC9240F61DAA9C7144B682A430A3A1366576F840BF2D070101FCBC9A02D")
    }

    /// m/0H ext pub
    func testVector41() throws {
        let expected = try ExtendedPublicKey(from: "xpub69AUMk3qDBi3uW1sXgjCmVjJ2G6WQoYSnNHyzkmdCHEhSZ4tBok37xfFEqHd2AddP56Tqp4o56AePAgCjYdvpW2PU2jbUPFKsav5ut6Ch1m", networkType: .mainnet)

        XCTAssertEqual(expected.publicKey.hexString, "039382D2B6003446792D2917F7AC4B3EDF079A1A94DD4EB010DC25109DDA680A9D")
        XCTAssertEqual(expected.chainCode.hexString, "CDC0F06456A14876C898790E0B3B1A41C531170AEC69DA44FF7B7265BFE7743B")
    }

    /// m/0H/1H ext pub
    func testVector42() throws {
        let expected = try ExtendedPublicKey(from: "xpub6BJA1jSqiukeaesWfxe6sNK9CCGaujFFSJLomWHprUL9DePQ4JDkM5d88n49sMGJxrhpjazuXYWdMf17C9T5XnxkopaeS7jGk1GyyVziaMt", networkType: .mainnet)

        XCTAssertEqual(expected.publicKey.hexString, "032EDAF9E591EE27F3C69C36221E3C54C38088EF34E93FBB9BB2D4D9B92364CBBD")
        XCTAssertEqual(expected.chainCode.hexString, "A48EE6674C5264A237703FD383BCCD9FAD4D9378AC98AB05E6E7029B06360C0D")
    }

    // MARK: - Test vector 5

    // https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#user-content-Test_Vectors
    func testVector5() {
        // //(invalid pubkey 020000000000000000000000000000000000000000000000000000000000000007)
        XCTAssertThrowsError(try ExtendedPublicKey(from: "xpub661MyMwAqRbcEYS8w7XLSVeEsBXy79zSzH1J8vCdxAZningWLdN3zgtU6Q5JXayek4PRsn35jii4veMimro1xefsM58PgBMrvdYre8QyULY", networkType: .mainnet))

        // (unknown extended key version)
        XCTAssertThrowsError(try ExtendedPublicKey(from: "DMwo58pR1QLEFihHiXPVykYB6fJmsTeHvyTp7hRThAtCX8CvYzgPcn8XnmdfHPmHJiEDXkTiJTVV9rHEBUem2mwVbbNfvT2MTcAqj3nesx8uBf9", networkType:.mainnet))

        // (unknown extended key version)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "DMwo58pR1QLEFihHiXPVykYB6fJmsTeHvyTp7hRThAtCX8CvYzgPcn8XnmdfHGMQzT7ayAmfo4z3gY5KfbrZWZ6St24UVf2Qgo6oujFktLHdHY4", networkType:.mainnet))

        // (zero depth with non-zero index)
        XCTAssertThrowsError(try ExtendedPublicKey(from: "xpub661MyMwAuDcm6CRQ5N4qiHKrJ39Xe1R1NyfouMKTTWcguwVcfrZJaNvhpebzGerh7gucBvzEQWRugZDuDXjNDRmXzSZe4c7mnTK97pTvGS8", networkType: .mainnet))

        // (zero depth with non-zero parent fingerprint)
        XCTAssertThrowsError(try ExtendedPublicKey(from: "xpub661no6RGEX3uJkY4bNnPcw4URcQTrSibUZ4NqJEw5eBkv7ovTwgiT91XX27VbEXGENhYRCf7hyEbWrR3FewATdCEebj6znwMfQkhRYHRLpJ", networkType: .mainnet))

        // (pubkey version / prvkey mismatch)
        XCTAssertThrowsError(try ExtendedPublicKey(from: "xpub661MyMwAqRbcEYS8w7XLSVeEsBXy79zSzH1J8vCdxAZningWLdN3zgtU6LBpB85b3D2yc8sfvZU521AAwdZafEz7mnzBBsz4wKY5fTtTQBm", networkType: .mainnet))

        // (prvkey version / pubkey mismatch)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "xprv9s21ZrQH143K24Mfq5zL5MhWK9hUhhGbd45hLXo2Pq2oqzMMo63oStZzFGTQQD3dC4H2D5GBj7vWvSQaaBv5cxi9gafk7NF3pnBju6dwKvH", networkType: .mainnet))

        // (invalid pubkey prefix 04)
        XCTAssertThrowsError(try ExtendedPublicKey(from: "xpub661MyMwAqRbcEYS8w7XLSVeEsBXy79zSzH1J8vCdxAZningWLdN3zgtU6Txnt3siSujt9RCVYsx4qHZGc62TG4McvMGcAUjeuwZdduYEvFn", networkType: .mainnet))

        // (invalid prvkey prefix 04)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "xprv9s21ZrQH143K24Mfq5zL5MhWK9hUhhGbd45hLXo2Pq2oqzMMo63oStZzFGpWnsj83BHtEy5Zt8CcDr1UiRXuWCmTQLxEK9vbz5gPstX92JQ", networkType: .mainnet))

        // (invalid pubkey prefix 01)
        XCTAssertThrowsError(try ExtendedPublicKey(from: "xpub661MyMwAqRbcEYS8w7XLSVeEsBXy79zSzH1J8vCdxAZningWLdN3zgtU6N8ZMMXctdiCjxTNq964yKkwrkBJJwpzZS4HS2fxvyYUA4q2Xe4", networkType: .mainnet))

        // (invalid prvkey prefix 01)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "xprv9s21ZrQH143K24Mfq5zL5MhWK9hUhhGbd45hLXo2Pq2oqzMMo63oStZzFAzHGBP2UuGCqWLTAPLcMtD9y5gkZ6Eq3Rjuahrv17fEQ3Qen6J", networkType: .mainnet))

        // (zero depth with non-zero parent fingerprint)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "xprv9s2SPatNQ9Vc6GTbVMFPFo7jsaZySyzk7L8n2uqKXJen3KUmvQNTuLh3fhZMBoG3G4ZW1N2kZuHEPY53qmbZzCHshoQnNf4GvELZfqTUrcv", networkType: .mainnet))

        // (zero depth with non-zero index)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "xprv9s21ZrQH4r4TsiLvyLXqM9P7k1K3EYhA1kkD6xuquB5i39AU8KF42acDyL3qsDbU9NmZn6MsGSUYZEsuoePmjzsB3eFKSUEh3Gu1N3cqVUN", networkType: .mainnet))

        // (private key 0 not in 1..n-1)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "xprv9s21ZrQH143K24Mfq5zL5MhWK9hUhhGbd45hLXo2Pq2oqzMMo63oStZzF93Y5wvzdUayhgkkFoicQZcP3y52uPPxFnfoLZB21Teqt1VvEHx", networkType: .mainnet))

        // (private key n not in 1..n-1)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "xprv9s21ZrQH143K24Mfq5zL5MhWK9hUhhGbd45hLXo2Pq2oqzMMo63oStZzFAzHGBP2UuGCqWLTAPLcMtD5SDKr24z3aiUvKr9bJpdrcLg1y3G", networkType: .mainnet))

        // (invalid checksum)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHL", networkType: .mainnet))
    }
}
