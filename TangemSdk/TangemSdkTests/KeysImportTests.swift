//
//  KeysImportTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 01.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import CryptoKit
@testable import TangemSdk

/// Test that keys uploaded to a card are equal to locally computed
@available(iOS 13.0, *)
class KeysImportTests: XCTestCase {
    private let entropy = Data(hexString: "6610b25967cdcca9d59875f5cb50b0ea75433311869e930b")
    private let mnemonicString = "gravity machine north sort system female filter attitude volume fold club stay feature office ecology stable narrow fog"
    private let passphrase = "TREZOR"
    private lazy var mnemonic = try! Mnemonic(with: mnemonicString)
    private lazy var seed = try! mnemonic.generateSeed(with: passphrase)

    func testKeyImportSecp256k1() throws {
        let privKey = try BIP32MasterKeyFactory(seed: seed, curve: .secp256k1).makePrivateKey()
        let pubKey = try privKey.makePublicKey(for: .secp256k1)

        XCTAssertEqual(pubKey.publicKey.hexString, "030B0DE47DF425C4BA08D77F927477195FB65E1B238E2366AA1B1BB82E0ACEE1A6")
        XCTAssertEqual(pubKey.chainCode.hexString, "B975E8D7517ED618CBBEBE87555E415874438B670C9E54E57F70FF02A15C4C10")
    }

    @available(iOS 16.0, *)
    func testKeyImportSchnorr() throws {
        let privKey = try BIP32MasterKeyFactory(seed: seed, curve: .bip0340).makePrivateKey()
        let pubKey = try privKey.makePublicKey(for: .bip0340)

        XCTAssertEqual(pubKey.publicKey.hexString, "0B0DE47DF425C4BA08D77F927477195FB65E1B238E2366AA1B1BB82E0ACEE1A6")
        XCTAssertEqual(pubKey.chainCode.hexString, "B975E8D7517ED618CBBEBE87555E415874438B670C9E54E57F70FF02A15C4C10")
    }
    
    @available(iOS 16.0, *)
    func testKeyImportSecp256r1() throws {
        let privKey = try BIP32MasterKeyFactory(seed: seed, curve: .secp256r1).makePrivateKey()
        let pubKey = (try P256.Signing.PrivateKey(rawRepresentation: privKey.privateKey)).publicKey.compressedRepresentation

        XCTAssertEqual(pubKey.hexString, "03D195B795DB30CB1CE7F13F29E1D7E072DA26ED79AB1D0E9F7C999C88A1C800C2")
        XCTAssertEqual(privKey.chainCode.hexString, "DB214B56C922478EA482F7AF007DB85FDCC8FB1AE03707A21371770EE7D5700F")
    }

    @available(iOS 16.0, *)
    func testKeyImportEd25519Slip0010() throws {
        let privKey = try BIP32MasterKeyFactory(seed: seed, curve: .ed25519slip0010).makePrivateKey()
        let pubKey = try privKey.makePublicKey(for: .ed25519slip0010)

        XCTAssertEqual(pubKey.publicKey.hexString, "335215FCF3105D6A379B8A0372A9E92B42CEED0B2D4E0D7E78E80D16DF41EA6B")
        XCTAssertEqual(pubKey.chainCode.hexString, "837FFAF1B96CA1ACD4A3CB9E08398DC1F21EC657A3BE7679435FC55F9FAE4A46")
    }

    func testKeyImportEd25519() throws {
        let privKey = try IkarusMasterKeyFactory(entropy: entropy, passphrase: passphrase).makePrivateKey()
        // from TrustWallet's WalletCore
        XCTAssertEqual(privKey.privateKey.hexString.lowercased(), "58b41cb27297be1fbf192a65e526179f43b779a383f5d72f14e5db8a82bd77525f65dbfe80724cd61254ec14b351312b63b51c87238ebd3c880a6ad158a161cb")
        XCTAssertEqual(privKey.chainCode.hexString.lowercased(), "4c3bd3e0df9ea6371678ccf2b741a762825783b8746e2527d8c15749e64b9d60")

        // from TrustWallet's WalletCore
        let pubKey = ExtendedPublicKey(publicKey: Data(hexString: "8d1dbcbe742b3db49533a3ee1166e9b69348fe200a2369443973b826e65b6a61"),
                                       chainCode: Data(hexString: "4c3bd3e0df9ea6371678ccf2b741a762825783b8746e2527d8c15749e64b9d60"))

        XCTAssertEqual(pubKey.publicKey.hexString, "8D1DBCBE742B3DB49533A3EE1166E9B69348FE200A2369443973B826E65B6A61")
        XCTAssertEqual(pubKey.chainCode.hexString, "4C3BD3E0DF9EA6371678CCF2B741A762825783B8746E2527D8C15749E64B9D60")
    }

    // All BLS schemes tested to produce same public key. Proof is not tested
    @available(iOS 16.0, *)
    func testKeyImportBLS() throws {
        let privKey = try EIP2333MasterKeyFactory(seed: seed).makePrivateKey()
        //static from code to prevent any changes in future
        XCTAssertEqual(privKey.privateKey.hexString, "3492BB55324A0F413798EA71856358556D25AD4EBC9458F062435C7B559E4670")
        XCTAssertEqual(privKey.chainCode.hexString, "")

        // https://iancoleman.io/blsttc_ui/
        let pubKey = ExtendedPublicKey(publicKey: Data(hexString: "a6d8551cfcf8aefa062c60ffa246466c158e017fba12570327f47a004d5846cf2fabc2952b8f1653f7d224efd9d9b826"), chainCode: Data())

        XCTAssertEqual(pubKey.publicKey.hexString, "A6D8551CFCF8AEFA062C60FFA246466C158E017FBA12570327F47A004D5846CF2FABC2952B8F1653F7D224EFD9D9B826")
        XCTAssertEqual(pubKey.chainCode.hexString, "")
    }
}
