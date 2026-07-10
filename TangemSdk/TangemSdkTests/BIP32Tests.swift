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

/// Tests for firmware 6.33
/// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#user-content-Test_Vectors
class BIP32Tests: XCTestCase {
    // MARK: - Test vector 1

    /// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#user-content-Test_Vectors
    func testVector1() throws {
        let seed = Data(hexString: "000102030405060708090a0b0c0d0e0f")
        let masterKey = try BIP32().makeMasterKey(from: seed, curve: .secp256k1)

        // Chain m
        try assertExtendedKeys(
            masterKey,
            xprv: "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi",
            xpub: "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8"
        )

        // Chain m/0H
        var derivedKey = try masterKey.derivePrivateKey(node: .hardened(0))
        try assertExtendedKeys(
            derivedKey,
            xprv: "xprv9uHRZZhk6KAJC1avXpDAp4MDc3sQKNxDiPvvkX8Br5ngLNv1TxvUxt4cV1rGL5hj6KCesnDYUhd7oWgT11eZG7XnxHrnYeSvkzY7d2bhkJ7",
            xpub: "xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw"
        )

        // Chain m/0H/1
        derivedKey = try derivedKey.derivePrivateKey(node: .nonHardened(1))
        try assertExtendedKeys(
            derivedKey,
            xprv: "xprv9wTYmMFdV23N2TdNG573QoEsfRrWKQgWeibmLntzniatZvR9BmLnvSxqu53Kw1UmYPxLgboyZQaXwTCg8MSY3H2EU4pWcQDnRnrVA1xe8fs",
            xpub: "xpub6ASuArnXKPbfEwhqN6e3mwBcDTgzisQN1wXN9BJcM47sSikHjJf3UFHKkNAWbWMiGj7Wf5uMash7SyYq527Hqck2AxYysAA7xmALppuCkwQ"
        )

        // Chain m/0H/1/2H
        derivedKey = try derivedKey.derivePrivateKey(node: .hardened(2))
        try assertExtendedKeys(
            derivedKey,
            xprv: "xprv9z4pot5VBttmtdRTWfWQmoH1taj2axGVzFqSb8C9xaxKymcFzXBDptWmT7FwuEzG3ryjH4ktypQSAewRiNMjANTtpgP4mLTj34bhnZX7UiM",
            xpub: "xpub6D4BDPcP2GT577Vvch3R8wDkScZWzQzMMUm3PWbmWvVJrZwQY4VUNgqFJPMM3No2dFDFGTsxxpG5uJh7n7epu4trkrX7x7DogT5Uv6fcLW5"
        )

        // Chain m/0H/1/2H/2
        derivedKey = try derivedKey.derivePrivateKey(node: .nonHardened(2))
        try assertExtendedKeys(
            derivedKey,
            xprv: "xprvA2JDeKCSNNZky6uBCviVfJSKyQ1mDYahRjijr5idH2WwLsEd4Hsb2Tyh8RfQMuPh7f7RtyzTtdrbdqqsunu5Mm3wDvUAKRHSC34sJ7in334",
            xpub: "xpub6FHa3pjLCk84BayeJxFW2SP4XRrFd1JYnxeLeU8EqN3vDfZmbqBqaGJAyiLjTAwm6ZLRQUMv1ZACTj37sR62cfN7fe5JnJ7dh8zL4fiyLHV"
        )

        // Chain m/0H/1/2H/2/1000000000
        derivedKey = try derivedKey.derivePrivateKey(node: .nonHardened(1000000000))
        try assertExtendedKeys(
            derivedKey,
            xprv: "xprvA41z7zogVVwxVSgdKUHDy1SKmdb533PjDz7J6N6mV6uS3ze1ai8FHa8kmHScGpWmj4WggLyQjgPie1rFSruoUihUZREPSL39UNdE3BBDu76",
            xpub: "xpub6H1LXWLaKsWFhvm6RVpEL9P4KfRZSW7abD2ttkWP3SSQvnyA8FSVqNTEcYFgJS2UaFcxupHiYkro49S8yGasTvXEYBVPamhGW6cFJodrTHy"
        )

        let derivedByPath = try masterKey.derivePrivateKey(path: DerivationPath(rawPath: "m/0'/1/2'/2/1000000000"))
        XCTAssertEqual(derivedByPath, derivedKey)
    }

    // MARK: - Test vector 2

    /// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#user-content-Test_Vectors
    func testVector2() throws {
        let seed = Data(hexString: "fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542")
        let masterKey = try BIP32().makeMasterKey(from: seed, curve: .secp256k1)

        // Chain m
        try assertExtendedKeys(
            masterKey,
            xprv: "xprv9s21ZrQH143K31xYSDQpPDxsXRTUcvj2iNHm5NUtrGiGG5e2DtALGdso3pGz6ssrdK4PFmM8NSpSBHNqPqm55Qn3LqFtT2emdEXVYsCzC2U",
            xpub: "xpub661MyMwAqRbcFW31YEwpkMuc5THy2PSt5bDMsktWQcFF8syAmRUapSCGu8ED9W6oDMSgv6Zz8idoc4a6mr8BDzTJY47LJhkJ8UB7WEGuduB"
        )

        // Chain m/0
        var derivedKey = try masterKey.derivePrivateKey(node: .nonHardened(0))
        try assertExtendedKeys(
            derivedKey,
            xprv: "xprv9vHkqa6EV4sPZHYqZznhT2NPtPCjKuDKGY38FBWLvgaDx45zo9WQRUT3dKYnjwih2yJD9mkrocEZXo1ex8G81dwSM1fwqWpWkeS3v86pgKt",
            xpub: "xpub69H7F5d8KSRgmmdJg2KhpAK8SR3DjMwAdkxj3ZuxV27CprR9LgpeyGmXUbC6wb7ERfvrnKZjXoUmmDznezpbZb7ap6r1D3tgFxHmwMkQTPH"
        )

        // Chain m/0/2147483647H
        derivedKey = try derivedKey.derivePrivateKey(node: .hardened(2147483647))
        try assertExtendedKeys(
            derivedKey,
            xprv: "xprv9wSp6B7kry3Vj9m1zSnLvN3xH8RdsPP1Mh7fAaR7aRLcQMKTR2vidYEeEg2mUCTAwCd6vnxVrcjfy2kRgVsFawNzmjuHc2YmYRmagcEPdU9",
            xpub: "xpub6ASAVgeehLbnwdqV6UKMHVzgqAG8Gr6riv3Fxxpj8ksbH9ebxaEyBLZ85ySDhKiLDBrQSARLq1uNRts8RuJiHjaDMBU4Zn9h8LZNnBC5y4a"
        )

        // Chain m/0/2147483647H/1
        derivedKey = try derivedKey.derivePrivateKey(node: .nonHardened(1))
        try assertExtendedKeys(
            derivedKey,
            xprv: "xprv9zFnWC6h2cLgpmSA46vutJzBcfJ8yaJGg8cX1e5StJh45BBciYTRXSd25UEPVuesF9yog62tGAQtHjXajPPdbRCHuWS6T8XA2ECKADdw4Ef",
            xpub: "xpub6DF8uhdarytz3FWdA8TvFSvvAh8dP3283MY7p2V4SeE2wyWmG5mg5EwVvmdMVCQcoNJxGoWaU9DCWh89LojfZ537wTfunKau47EL2dhHKon"
        )

        // Chain m/0/2147483647H/1/2147483646H
        derivedKey = try derivedKey.derivePrivateKey(node: .hardened(2147483646))
        try assertExtendedKeys(
            derivedKey,
            xprv: "xprvA1RpRA33e1JQ7ifknakTFpgNXPmW2YvmhqLQYMmrj4xJXXWYpDPS3xz7iAxn8L39njGVyuoseXzU6rcxFLJ8HFsTjSyQbLYnMpCqE2VbFWc",
            xpub: "xpub6ERApfZwUNrhLCkDtcHTcxd75RbzS1ed54G1LkBUHQVHQKqhMkhgbmJbZRkrgZw4koxb5JaHWkY4ALHY2grBGRjaDMzQLcgJvLJuZZvRcEL"
        )

        // Chain m/0/2147483647H/1/2147483646H/2
        derivedKey = try derivedKey.derivePrivateKey(node: .nonHardened(2))
        try assertExtendedKeys(
            derivedKey,
            xprv: "xprvA2nrNbFZABcdryreWet9Ea4LvTJcGsqrMzxHx98MMrotbir7yrKCEXw7nadnHM8Dq38EGfSh6dqA9QWTyefMLEcBYJUuekgW4BYPJcr9E7j",
            xpub: "xpub6FnCn6nSzZAw5Tw7cgR9bi15UV96gLZhjDstkXXxvCLsUXBGXPdSnLFbdpq8p9HmGsApME5hQTZ3emM2rnY5agb9rXpVGyy3bdW6EEgAtqt"
        )

        let derivedByPath = try masterKey.derivePrivateKey(path: DerivationPath(rawPath: "m/0/2147483647'/1/2147483646'/2"))
        XCTAssertEqual(derivedByPath, derivedKey)
    }

    // MARK: - Test vector 3

    /// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#user-content-Test_Vectors
    func testVector3() throws {
        let seed = Data(hexString: "4b381541583be4423346c643850da4b320e46a87ae3d2a4e6da11eba819cd4acba45d239319ac14f863b8d5ab5a0d0c64d2e8a1e7d1457df2e5a3c51c73235be")
        let masterKey = try BIP32().makeMasterKey(from: seed, curve: .secp256k1)

        // Chain m
        try assertExtendedKeys(
            masterKey,
            xprv: "xprv9s21ZrQH143K25QhxbucbDDuQ4naNntJRi4KUfWT7xo4EKsHt2QJDu7KXp1A3u7Bi1j8ph3EGsZ9Xvz9dGuVrtHHs7pXeTzjuxBrCmmhgC6",
            xpub: "xpub661MyMwAqRbcEZVB4dScxMAdx6d4nFc9nvyvH3v4gJL378CSRZiYmhRoP7mBy6gSPSCYk6SzXPTf3ND1cZAceL7SfJ1Z3GC8vBgp2epUt13"
        )

        // Chain m/0H
        let derivedKey = try masterKey.derivePrivateKey(node: .hardened(0))
        try assertExtendedKeys(
            derivedKey,
            xprv: "xprv9uPDJpEQgRQfDcW7BkF7eTya6RPxXeJCqCJGHuCJ4GiRVLzkTXBAJMu2qaMWPrS7AANYqdq6vcBcBUdJCVVFceUvJFjaPdGZ2y9WACViL4L",
            xpub: "xpub68NZiKmJWnxxS6aaHmn81bvJeTESw724CRDs6HbuccFQN9Ku14VQrADWgqbhhTHBaohPX4CjNLf9fq9MYo6oDaPPLPxSb7gwQN3ih19Zm4Y"
        )

        let derivedByPath = try masterKey.derivePrivateKey(path: DerivationPath(rawPath: "m/0'"))
        XCTAssertEqual(derivedByPath, derivedKey)
    }

    // MARK: - Test vector 4

    /// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#user-content-Test_Vectors
    func testVector4() throws {
        let seed = Data(hexString: "3ddd5602285899a946114506157c7997e5444528f3003f6134712147db19b678")
        let masterKey = try BIP32().makeMasterKey(from: seed, curve: .secp256k1)

        // Chain m
        try assertExtendedKeys(
            masterKey,
            xprv: "xprv9s21ZrQH143K48vGoLGRPxgo2JNkJ3J3fqkirQC2zVdk5Dgd5w14S7fRDyHH4dWNHUgkvsvNDCkvAwcSHNAQwhwgNMgZhLtQC63zxwhQmRv",
            xpub: "xpub661MyMwAqRbcGczjuMoRm6dXaLDEhW1u34gKenbeYqAix21mdUKJyuyu5F1rzYGVxyL6tmgBUAEPrEz92mBXjByMRiJdba9wpnN37RLLAXa"
        )

        // Chain m/0H
        var derivedKey = try masterKey.derivePrivateKey(node: .hardened(0))
        try assertExtendedKeys(
            derivedKey,
            xprv: "xprv9vB7xEWwNp9kh1wQRfCCQMnZUEG21LpbR9NPCNN1dwhiZkjjeGRnaALmPXCX7SgjFTiCTT6bXes17boXtjq3xLpcDjzEuGLQBM5ohqkao9G",
            xpub: "xpub69AUMk3qDBi3uW1sXgjCmVjJ2G6WQoYSnNHyzkmdCHEhSZ4tBok37xfFEqHd2AddP56Tqp4o56AePAgCjYdvpW2PU2jbUPFKsav5ut6Ch1m"
        )

        // Chain m/0H/1H
        derivedKey = try derivedKey.derivePrivateKey(node: .hardened(1))
        try assertExtendedKeys(
            derivedKey,
            xprv: "xprv9xJocDuwtYCMNAo3Zw76WENQeAS6WGXQ55RCy7tDJ8oALr4FWkuVoHJeHVAcAqiZLE7Je3vZJHxspZdFHfnBEjHqU5hG1Jaj32dVoS6XLT1",
            xpub: "xpub6BJA1jSqiukeaesWfxe6sNK9CCGaujFFSJLomWHprUL9DePQ4JDkM5d88n49sMGJxrhpjazuXYWdMf17C9T5XnxkopaeS7jGk1GyyVziaMt"
        )

        let derivedByPath = try masterKey.derivePrivateKey(path: DerivationPath(rawPath: "m/0'/1'"))
        XCTAssertEqual(derivedByPath, derivedKey)
    }

    // MARK: - Test vector 5

    /// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#user-content-Test_Vectors
    func testVector5() {
        // (invalid pubkey 020000000000000000000000000000000000000000000000000000000000000007)
        XCTAssertThrowsError(try ExtendedPublicKey(from: "xpub661MyMwAqRbcEYS8w7XLSVeEsBXy79zSzH1J8vCdxAZningWLdN3zgtU6Q5JXayek4PRsn35jii4veMimro1xefsM58PgBMrvdYre8QyULY", networkType: .mainnet))

        // (unknown extended key version)
        XCTAssertThrowsError(try ExtendedPublicKey(from: "DMwo58pR1QLEFihHiXPVykYB6fJmsTeHvyTp7hRThAtCX8CvYzgPcn8XnmdfHPmHJiEDXkTiJTVV9rHEBUem2mwVbbNfvT2MTcAqj3nesx8uBf9", networkType: .mainnet))

        // (unknown extended key version)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "DMwo58pR1QLEFihHiXPVykYB6fJmsTeHvyTp7hRThAtCX8CvYzgPcn8XnmdfHGMQzT7ayAmfo4z3gY5KfbrZWZ6St24UVf2Qgo6oujFktLHdHY4", networkType: .mainnet))

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

    // MARK: - Derivation retry

    /// BIP32: "In case parse256(IL) ≥ n or ki = 0, the resulting key is invalid, and one should proceed with the next value for i."
    /// No real seed and path can hit this case on secp256k1 (the probability is lower than 1 in 2^127), so the digests are crafted:
    /// `IL = n`, and `IL = n - kpar` of the test vector 1 master key — the only value that gives `ki = 0` and `Ki = the point at infinity`.
    private let overflowedIL = Data(hexString: "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141")
    private let zeroChildIL = Data(hexString: "170cd18dc2130bfae5105371d36c3639089aabae977af021ab3da57507f2d60c")

    func testInvalidPrivateChildKeyDetection() throws {
        let masterKey = try BIP32().makeMasterKey(from: Data(hexString: "000102030405060708090a0b0c0d0e0f"), curve: .secp256k1)
        let parentPublicKey = try masterKey.makePublicKey(for: .secp256k1).publicKey

        for il in [overflowedIL, zeroChildIL] {
            XCTAssertThrowsError(try masterKey.makeChildKey(digest: il + masterKey.chainCode, index: 0, parentPublicKey: parentPublicKey)) { error in
                XCTAssertEqual(error as? HDWalletError, .invalidChildKey)
            }
        }
    }

    func testInvalidPublicChildKeyDetection() throws {
        let masterKey = ExtendedPublicKey(
            publicKey: Data(hexString: "0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2"),
            chainCode: Data(hexString: "873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508")
        )

        for il in [overflowedIL, zeroChildIL] {
            XCTAssertThrowsError(try masterKey.makeChildKey(digest: il + masterKey.chainCode, index: 0)) { error in
                XCTAssertEqual(error as? HDWalletError, .invalidChildKey)
            }
        }
    }

    func testPrivateKeyDerivationProceedsWithTheNextIndex() throws {
        let masterKey = try BIP32().makeMasterKey(from: Data(hexString: "000102030405060708090a0b0c0d0e0f"), curve: .secp256k1)
        let parentPublicKey = try masterKey.makePublicKey(for: .secp256k1).publicKey

        let derivedKey = try BIP32.deriveWithRetry(from: 0) { index in
            let digest = index == 0
                ? zeroChildIL + masterKey.chainCode
                : Data(HMAC<SHA512>.authenticationCode(for: parentPublicKey + index.bytes4, using: SymmetricKey(data: masterKey.chainCode)))

            return try masterKey.makeChildKey(digest: digest, index: index, parentPublicKey: parentPublicKey)
        }

        XCTAssertEqual(derivedKey, try masterKey.derivePrivateKey(node: .nonHardened(1)))
        XCTAssertEqual(derivedKey.childNumber, 1)
    }

    func testPublicKeyDerivationProceedsWithTheNextIndex() throws {
        let masterKey = ExtendedPublicKey(
            publicKey: Data(hexString: "0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2"),
            chainCode: Data(hexString: "873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508")
        )

        let derivedKey = try BIP32.deriveWithRetry(from: 0) { index in
            let digest = index == 0
                ? zeroChildIL + masterKey.chainCode
                : Data(HMAC<SHA512>.authenticationCode(for: masterKey.publicKey + index.bytes4, using: SymmetricKey(data: masterKey.chainCode)))

            return try masterKey.makeChildKey(digest: digest, index: index)
        }

        XCTAssertEqual(derivedKey, try masterKey.derivePublicKey(node: .nonHardened(1)))
        XCTAssertEqual(derivedKey.childNumber, 1)
    }

    func testDeriveWithRetryPropagatesOtherErrors() {
        var attempts = 0

        XCTAssertThrowsError(
            try BIP32.deriveWithRetry(from: 0) { _ in
                attempts += 1
                throw HDWalletError.hardenedNotSupported
            }
        ) { error in
            XCTAssertEqual(error as? HDWalletError, .hardenedNotSupported)
        }

        XCTAssertEqual(attempts, 1)
    }

    func testDeriveWithRetryFailsOnIndexOverflow() {
        var attemptedIndexes: [UInt32] = []

        XCTAssertThrowsError(
            try BIP32.deriveWithRetry(from: UInt32.max - 1) { index in
                attemptedIndexes.append(index)
                throw HDWalletError.invalidChildKey
            }
        ) { error in
            XCTAssertEqual(error as? HDWalletError, .invalidChildKey)
        }

        XCTAssertEqual(attemptedIndexes, [UInt32.max - 1, UInt32.max])
    }

    // MARK: - Hardened index semantics

    /// BIP32 defines hardened derivation solely by `i ≥ 2^31`, regardless of how the node was constructed.
    func testNonHardenedNodeWithHardenedIndex() throws {
        let masterKey = try BIP32().makeMasterKey(from: Data(hexString: "000102030405060708090a0b0c0d0e0f"), curve: .secp256k1)

        XCTAssertEqual(
            try masterKey.derivePrivateKey(node: .nonHardened(2147483648)),
            try masterKey.derivePrivateKey(node: .hardened(0))
        )

        XCTAssertThrowsError(try masterKey.makePublicKey(for: .secp256k1).derivePublicKey(node: .nonHardened(2147483648))) { error in
            XCTAssertEqual(error as? HDWalletError, .hardenedNotSupported)
        }
    }

    // MARK: - Helpers

    private func assertExtendedKeys(_ key: ExtendedPrivateKey, xprv: String, xpub: String, file: StaticString = #filePath, line: UInt = #line) throws {
        XCTAssertEqual(try key.serialize(for: .mainnet), xprv, file: file, line: line)
        XCTAssertEqual(try key.makePublicKey(for: .secp256k1).serialize(for: .mainnet), xpub, file: file, line: line)
    }
}

// MARK: - SLIP10FWTests

class BIP32FWTests: FWTestCase {
    func testVector1() throws {
        let sdk = TangemSdk()
        sdk.config.defaultDerivationPaths = [.secp256k1: [
            try DerivationPath(rawPath: "m/0'"),
            try DerivationPath(rawPath: "m/0'/1"),
            try DerivationPath(rawPath: "m/0'/1/2'"),
            try DerivationPath(rawPath: "m/0'/1/2'/2"),
            try DerivationPath(rawPath: "m/0'/1/2'/2/1000000000"),
        ]]

        let seed = Data(hexString: "000102030405060708090a0b0c0d0e0f")
        let bip32 = BIP32()

        let mPrv = try bip32.makeMasterKey(from: seed, curve: .secp256k1)
        let mPub = try mPrv.makePublicKey(for: .secp256k1)

        let xPrv = try mPrv.serialize(for: .mainnet)
        printEquals(xPrv, "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi")

        let xPub = try mPub.serialize(for: .mainnet)
        printEquals(xPub, "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8")

        let iw = CreateWalletTask(curve: .secp256k1, privateKey: mPrv)

        sdk.startSession(with: iw) { result in
            do {
                switch result {
                case .success(let response):
                    let wallet = response.wallet

                    // Chain m
                    let expectedM = try ExtendedPublicKey(from: "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8", networkType: .mainnet)
                    let publicKey = try XCTUnwrap(wallet.publicKey)
                    let chainCode = try XCTUnwrap(wallet.chainCode)
                    self.printEquals(expectedM.publicKey.hexString, publicKey.hexString)
                    self.printEquals(expectedM.chainCode.hexString, chainCode.hexString)

                    // Chain m/0H ext pub
                    let derived = try XCTUnwrap(wallet.derivedKeys[try DerivationPath(rawPath: "m/0'")])
                    let expected = try ExtendedPublicKey(from: "xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw", networkType: .mainnet)
                    self.printEquals(expected.publicKey.hexString, derived.publicKey.hexString)
                    self.printEquals(expected.chainCode.hexString, derived.chainCode.hexString)

                    // Chain m/0H/1 ext pub
                    let derived1 = try XCTUnwrap(wallet.derivedKeys[try DerivationPath(rawPath: "m/0'/1")])
                    let expected1 = try ExtendedPublicKey(from: "xpub6ASuArnXKPbfEwhqN6e3mwBcDTgzisQN1wXN9BJcM47sSikHjJf3UFHKkNAWbWMiGj7Wf5uMash7SyYq527Hqck2AxYysAA7xmALppuCkwQ", networkType: .mainnet)
                    self.printEquals(expected1.publicKey.hexString, derived1.publicKey.hexString)
                    self.printEquals(expected1.chainCode.hexString, derived1.chainCode.hexString)

                    // Chain m/0H/1/2H ext pub
                    let derived2 = try XCTUnwrap(wallet.derivedKeys[try DerivationPath(rawPath: "m/0'/1/2'")])
                    let expected2 = try ExtendedPublicKey(from: "xpub6D4BDPcP2GT577Vvch3R8wDkScZWzQzMMUm3PWbmWvVJrZwQY4VUNgqFJPMM3No2dFDFGTsxxpG5uJh7n7epu4trkrX7x7DogT5Uv6fcLW5", networkType: .mainnet)
                    self.printEquals(expected2.publicKey.hexString, derived2.publicKey.hexString)
                    self.printEquals(expected2.chainCode.hexString, derived2.chainCode.hexString)

                    // Chain m/0H/1/2H/2 ext pub
                    let derived3 = try XCTUnwrap(wallet.derivedKeys[try DerivationPath(rawPath: "m/0'/1/2'/2")])
                    let expected3 = try ExtendedPublicKey(from: "xpub6FHa3pjLCk84BayeJxFW2SP4XRrFd1JYnxeLeU8EqN3vDfZmbqBqaGJAyiLjTAwm6ZLRQUMv1ZACTj37sR62cfN7fe5JnJ7dh8zL4fiyLHV", networkType: .mainnet)
                    self.printEquals(expected3.publicKey.hexString, derived3.publicKey.hexString)
                    self.printEquals(expected3.chainCode.hexString, derived3.chainCode.hexString)

                    // Chain m/0H/1/2H/2/1000000000 ext pub
                    let derived4 = try XCTUnwrap(wallet.derivedKeys[try DerivationPath(rawPath: "m/0'/1/2'/2/1000000000")])
                    let expected4 = try ExtendedPublicKey(from: "xpub6H1LXWLaKsWFhvm6RVpEL9P4KfRZSW7abD2ttkWP3SSQvnyA8FSVqNTEcYFgJS2UaFcxupHiYkro49S8yGasTvXEYBVPamhGW6cFJodrTHy", networkType: .mainnet)
                    self.printEquals(expected4.publicKey.hexString, derived4.publicKey.hexString)
                    self.printEquals(expected4.chainCode.hexString, derived4.chainCode.hexString)

                case .failure(let error):
                    print(error)
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }

            withExtendedLifetime(sdk) {}
        }
    }

    func testVector2() throws {
        let sdk = TangemSdk()
        sdk.config.defaultDerivationPaths = [.secp256k1: [
            try DerivationPath(rawPath: "m/0"),
            try DerivationPath(rawPath: "m/0/2147483647'"),
            try DerivationPath(rawPath: "m/0/2147483647'/1"),
            try DerivationPath(rawPath: "m/0/2147483647'/1/2147483646'"),
            try DerivationPath(rawPath: "m/0/2147483647'/1/2147483646'/2"),
        ]]

        let seed = Data(hexString: "fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542")
        let bip32 = BIP32()

        let mPrv = try bip32.makeMasterKey(from: seed, curve: .secp256k1)
        let mPub = try mPrv.makePublicKey(for: .secp256k1)

        let xPrv = try mPrv.serialize(for: .mainnet)
        printEquals(xPrv, "xprv9s21ZrQH143K31xYSDQpPDxsXRTUcvj2iNHm5NUtrGiGG5e2DtALGdso3pGz6ssrdK4PFmM8NSpSBHNqPqm55Qn3LqFtT2emdEXVYsCzC2U")

        let xPub = try mPub.serialize(for: .mainnet)
        printEquals(xPub, "xpub661MyMwAqRbcFW31YEwpkMuc5THy2PSt5bDMsktWQcFF8syAmRUapSCGu8ED9W6oDMSgv6Zz8idoc4a6mr8BDzTJY47LJhkJ8UB7WEGuduB")

        let iw = CreateWalletTask(curve: .secp256k1, privateKey: mPrv)

        sdk.startSession(with: iw) { result in
            do {
                switch result {
                case .success(let response):
                    let wallet = response.wallet

                    // Chain m
                    let expectedM = try ExtendedPublicKey(from: "xpub661MyMwAqRbcFW31YEwpkMuc5THy2PSt5bDMsktWQcFF8syAmRUapSCGu8ED9W6oDMSgv6Zz8idoc4a6mr8BDzTJY47LJhkJ8UB7WEGuduB", networkType: .mainnet)
                    let publicKey = try XCTUnwrap(wallet.publicKey)
                    let chainCode = try XCTUnwrap(wallet.chainCode)
                    self.printEquals(expectedM.publicKey.hexString, publicKey.hexString)
                    self.printEquals(expectedM.chainCode.hexString, chainCode.hexString)

                    // Chain m/0 ext pub
                    let derived = try XCTUnwrap(wallet.derivedKeys[try DerivationPath(rawPath: "m/0")])
                    let expected = try ExtendedPublicKey(from: "xpub69H7F5d8KSRgmmdJg2KhpAK8SR3DjMwAdkxj3ZuxV27CprR9LgpeyGmXUbC6wb7ERfvrnKZjXoUmmDznezpbZb7ap6r1D3tgFxHmwMkQTPH", networkType: .mainnet)
                    self.printEquals(expected.publicKey.hexString, derived.publicKey.hexString)
                    self.printEquals(expected.chainCode.hexString, derived.chainCode.hexString)

                    // Chain m/0/2147483647H ext pub
                    let derived1 = try XCTUnwrap(wallet.derivedKeys[try DerivationPath(rawPath: "m/0/2147483647'")])
                    let expected1 = try ExtendedPublicKey(from: "xpub6ASAVgeehLbnwdqV6UKMHVzgqAG8Gr6riv3Fxxpj8ksbH9ebxaEyBLZ85ySDhKiLDBrQSARLq1uNRts8RuJiHjaDMBU4Zn9h8LZNnBC5y4a", networkType: .mainnet)
                    self.printEquals(expected1.publicKey.hexString, derived1.publicKey.hexString)
                    self.printEquals(expected1.chainCode.hexString, derived1.chainCode.hexString)

                    // Chain m/0/2147483647H/1 ext pub
                    let derived2 = try XCTUnwrap(wallet.derivedKeys[try DerivationPath(rawPath: "m/0/2147483647'/1")])
                    let expected2 = try ExtendedPublicKey(from: "xpub6DF8uhdarytz3FWdA8TvFSvvAh8dP3283MY7p2V4SeE2wyWmG5mg5EwVvmdMVCQcoNJxGoWaU9DCWh89LojfZ537wTfunKau47EL2dhHKon", networkType: .mainnet)
                    self.printEquals(expected2.publicKey.hexString, derived2.publicKey.hexString)
                    self.printEquals(expected2.chainCode.hexString, derived2.chainCode.hexString)

                    // Chain m/0/2147483647H/1/2147483646H  ext pub
                    let derived3 = try XCTUnwrap(wallet.derivedKeys[try DerivationPath(rawPath: "m/0/2147483647'/1/2147483646'")])
                    let expected3 = try ExtendedPublicKey(from: "xpub6ERApfZwUNrhLCkDtcHTcxd75RbzS1ed54G1LkBUHQVHQKqhMkhgbmJbZRkrgZw4koxb5JaHWkY4ALHY2grBGRjaDMzQLcgJvLJuZZvRcEL", networkType: .mainnet)
                    self.printEquals(expected3.publicKey.hexString, derived3.publicKey.hexString)
                    self.printEquals(expected3.chainCode.hexString, derived3.chainCode.hexString)

                    // Chain m/0/2147483647H/1/2147483646H/2 ext pub
                    let derived4 = try XCTUnwrap(wallet.derivedKeys[try DerivationPath(rawPath: "m/0/2147483647'/1/2147483646'/2")])
                    let expected4 = try ExtendedPublicKey(from: "xpub6FnCn6nSzZAw5Tw7cgR9bi15UV96gLZhjDstkXXxvCLsUXBGXPdSnLFbdpq8p9HmGsApME5hQTZ3emM2rnY5agb9rXpVGyy3bdW6EEgAtqt", networkType: .mainnet)
                    self.printEquals(expected4.publicKey.hexString, derived4.publicKey.hexString)
                    self.printEquals(expected4.chainCode.hexString, derived4.chainCode.hexString)

                case .failure(let error):
                    print(error)
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }

            withExtendedLifetime(sdk) {}
        }
    }

    func testVector3() throws {
        let sdk = TangemSdk()
        sdk.config.defaultDerivationPaths = [.secp256k1: [
            try DerivationPath(rawPath: "m/0'"),
        ]]

        let seed = Data(hexString: "4b381541583be4423346c643850da4b320e46a87ae3d2a4e6da11eba819cd4acba45d239319ac14f863b8d5ab5a0d0c64d2e8a1e7d1457df2e5a3c51c73235be")
        let bip32 = BIP32()

        let mPrv = try bip32.makeMasterKey(from: seed, curve: .secp256k1)
        let mPub = try mPrv.makePublicKey(for: .secp256k1)

        let xPrv = try mPrv.serialize(for: .mainnet)
        printEquals(xPrv, "xprv9s21ZrQH143K25QhxbucbDDuQ4naNntJRi4KUfWT7xo4EKsHt2QJDu7KXp1A3u7Bi1j8ph3EGsZ9Xvz9dGuVrtHHs7pXeTzjuxBrCmmhgC6")

        let xPub = try mPub.serialize(for: .mainnet)
        printEquals(xPub, "xpub661MyMwAqRbcEZVB4dScxMAdx6d4nFc9nvyvH3v4gJL378CSRZiYmhRoP7mBy6gSPSCYk6SzXPTf3ND1cZAceL7SfJ1Z3GC8vBgp2epUt13")

        let iw = CreateWalletTask(curve: .secp256k1, privateKey: mPrv)

        sdk.startSession(with: iw) { result in
            do {
                switch result {
                case .success(let response):
                    let wallet = response.wallet

                    // Chain m
                    let expectedM = try ExtendedPublicKey(from: "xpub661MyMwAqRbcEZVB4dScxMAdx6d4nFc9nvyvH3v4gJL378CSRZiYmhRoP7mBy6gSPSCYk6SzXPTf3ND1cZAceL7SfJ1Z3GC8vBgp2epUt13", networkType: .mainnet)
                    let publicKey = try XCTUnwrap(wallet.publicKey)
                    let chainCode = try XCTUnwrap(wallet.chainCode)
                    self.printEquals(expectedM.publicKey.hexString, publicKey.hexString)
                    self.printEquals(expectedM.chainCode.hexString, chainCode.hexString)

                    // Chain m/0' ext pub
                    let derived = try XCTUnwrap(wallet.derivedKeys[try DerivationPath(rawPath: "m/0'")])
                    let expected = try ExtendedPublicKey(from: "xpub68NZiKmJWnxxS6aaHmn81bvJeTESw724CRDs6HbuccFQN9Ku14VQrADWgqbhhTHBaohPX4CjNLf9fq9MYo6oDaPPLPxSb7gwQN3ih19Zm4Y", networkType: .mainnet)
                    self.printEquals(expected.publicKey.hexString, derived.publicKey.hexString)
                    self.printEquals(expected.chainCode.hexString, derived.chainCode.hexString)

                case .failure(let error):
                    print(error)
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }

            withExtendedLifetime(sdk) {}
        }
    }

    func testVector4() throws {
        let sdk = TangemSdk()
        sdk.config.defaultDerivationPaths = [.secp256k1: [
            try DerivationPath(rawPath: "m/0'"),
            try DerivationPath(rawPath: "m/0'/1'"),
        ]]

        let seed = Data(hexString: "3ddd5602285899a946114506157c7997e5444528f3003f6134712147db19b678")
        let bip32 = BIP32()

        let mPrv = try bip32.makeMasterKey(from: seed, curve: .secp256k1)
        let mPub = try mPrv.makePublicKey(for: .secp256k1)

        let xPrv = try mPrv.serialize(for: .mainnet)
        printEquals(xPrv, "xprv9s21ZrQH143K48vGoLGRPxgo2JNkJ3J3fqkirQC2zVdk5Dgd5w14S7fRDyHH4dWNHUgkvsvNDCkvAwcSHNAQwhwgNMgZhLtQC63zxwhQmRv")

        let xPub = try mPub.serialize(for: .mainnet)
        printEquals(xPub, "xpub661MyMwAqRbcGczjuMoRm6dXaLDEhW1u34gKenbeYqAix21mdUKJyuyu5F1rzYGVxyL6tmgBUAEPrEz92mBXjByMRiJdba9wpnN37RLLAXa")

        let iw = CreateWalletTask(curve: .secp256k1, privateKey: mPrv)

        sdk.startSession(with: iw) { result in
            do {
                switch result {
                case .success(let response):
                    let wallet = response.wallet

                    // Chain m
                    let expectedM = try ExtendedPublicKey(from: "xpub661MyMwAqRbcGczjuMoRm6dXaLDEhW1u34gKenbeYqAix21mdUKJyuyu5F1rzYGVxyL6tmgBUAEPrEz92mBXjByMRiJdba9wpnN37RLLAXa", networkType: .mainnet)
                    let publicKey = try XCTUnwrap(wallet.publicKey)
                    let chainCode = try XCTUnwrap(wallet.chainCode)
                    self.printEquals(expectedM.publicKey.hexString, publicKey.hexString)
                    self.printEquals(expectedM.chainCode.hexString, chainCode.hexString)

                    // Chain m/0' ext pub
                    let derived = try XCTUnwrap(wallet.derivedKeys[try DerivationPath(rawPath: "m/0'")])
                    let expected = try ExtendedPublicKey(from: "xpub69AUMk3qDBi3uW1sXgjCmVjJ2G6WQoYSnNHyzkmdCHEhSZ4tBok37xfFEqHd2AddP56Tqp4o56AePAgCjYdvpW2PU2jbUPFKsav5ut6Ch1m", networkType: .mainnet)
                    self.printEquals(expected.publicKey.hexString, derived.publicKey.hexString)
                    self.printEquals(expected.chainCode.hexString, derived.chainCode.hexString)

                    // Chain m/0H/1H ext pub
                    let derived1 = try XCTUnwrap(wallet.derivedKeys[try DerivationPath(rawPath: "m/0'/1'")])
                    let expected1 = try ExtendedPublicKey(from: "xpub6BJA1jSqiukeaesWfxe6sNK9CCGaujFFSJLomWHprUL9DePQ4JDkM5d88n49sMGJxrhpjazuXYWdMf17C9T5XnxkopaeS7jGk1GyyVziaMt", networkType: .mainnet)
                    self.printEquals(expected1.publicKey.hexString, derived1.publicKey.hexString)
                    self.printEquals(expected1.chainCode.hexString, derived1.chainCode.hexString)

                case .failure(let error):
                    print(error)
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }

            withExtendedLifetime(sdk) {}
        }
    }
}
