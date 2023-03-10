//
//  ExtendedKeyTests.swift.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 13.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import Foundation
@testable import TangemSdk

@available(iOS 13.0, *)
class ExtendedKeyTests: XCTestCase {
    func testRoundTripPub() throws {
        let key = try ExtendedPublicKey(
            publicKey: Data(hexString: "0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2"),
            chainCode:  Data(hexString: "873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508"),
            depth: 3,
            parentFingerprint: Data(hexString: "0x00000000"),
            childNumber: 2147483648
        )

        let xpubString = try key.serialize(for: .mainnet)
        let deserializedKey = try ExtendedPublicKey(from: xpubString, networkType: .mainnet)

        XCTAssertEqual(key, deserializedKey)
    }

    func testRoundTripPriv() throws {
        let xpriv = "xprv9s21ZrQH143K3Dp5U6YoTum8c6rvMLxbEncwSjfnq12ShNzEhwbCmfvQDPNQTCsEcZJZcLrnf6rt6MCzsMiJYrhLGQwkK1uPCC5QsiAu4tW"
        let key = try ExtendedPrivateKey(from: xpriv, networkType: .mainnet)
        let serialized = try key.serialize(for: .mainnet)
        XCTAssertEqual(xpriv, serialized)
    }

    func testDerived() throws {
        let parentKey = Data(hexString: "0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2")
        let parentFingerprint = parentKey.sha256Ripemd160.prefix(4)

        let key = ExtendedPublicKey(
            publicKey: Data(hexString: "0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2"),
            chainCode: Data(hexString: "873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508")
        )

        let derivedKey = try key.derivePublicKey(node: .nonHardened(2))

        XCTAssertEqual(derivedKey.parentFingerprint, parentFingerprint)
        XCTAssertEqual(derivedKey.depth, 1)
        XCTAssertEqual(derivedKey.childNumber, 2)
    }

    func testInitMaster() throws {
        let key = ExtendedPublicKey(
            publicKey: Data(hexString: "0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2"),
            chainCode: Data(hexString: "873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508")
        )

        XCTAssertEqual(key.depth, 0)
        XCTAssertEqual(key.parentFingerprint, Data(hexString: "0x00000000"))
        XCTAssertEqual(key.childNumber, 0)
    }

    func testSerializeEdKey() {
        let key = ExtendedPublicKey(publicKey: Data(hexString: "9FE5BB2CC7D83C1DA10845AFD8A34B141FD8FD72500B95B1547E12B9BB8AAC3D"),
                                    chainCode: Data(hexString: "02fc9e5af0ac8d9b3cecfe2a888e2117ba3d089d8585886c9c826b6b22a98d12ea"))
        XCTAssertThrowsError(try key.serialize(for: .mainnet))
    }

    func testSerialization() throws {
        let mKeyString = "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8"
        let mXpubKey = try ExtendedPublicKey(from: mKeyString, networkType: .mainnet)

        let key = try ExtendedPublicKey(
            publicKey: Data(hexString: "035a784662a4a20a65bf6aab9ae98a6c068a81c52e4b032c0fb5400c706cfccc56"),
            chainCode: Data(hexString: "47fdacbd0f1097043b78c63c20c34ef4ed9a111d980047ad16282c7ae6236141"),
            depth: 1,
            parentFingerprint: mXpubKey.publicKey.sha256Ripemd160.prefix(4),
            childNumber: 2147483648
            )

        let serialized = try key.serialize(for: .mainnet)
        XCTAssertEqual(serialized, "xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw")
    }

    // https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#user-content-Test_Vectors
    func testBadKeys() {
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
