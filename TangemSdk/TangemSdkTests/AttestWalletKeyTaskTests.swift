//
//  AttestWalletKeyTaskTests.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemSdk

/// Tests for the card-signature verification logic of `AttestWalletKeyTask`.
/// Real secp256k1 key pairs and signatures are produced in-test so that the
/// cryptographic checks run end-to-end rather than against canned data.
class AttestWalletKeyTaskTests: XCTestCase {
    private let challenge = Data(repeating: 1, count: 16)
    private let publicKeySalt = Data(repeating: 9, count: 16)

    private var cardKeyPair: KeyPair!
    private var walletKeyPair: KeyPair!

    override func setUpWithError() throws {
        cardKeyPair = try Secp256k1Utils().generateKeyPair()
        walletKeyPair = try Secp256k1Utils().generateKeyPair()
    }

    func testNoneModeAbsentSignatureIsAccepted() throws {
        // The card signature was never requested, so its absence is expected and accepted.
        let isValid = try makeTask(confirmationMode: .none).verifyCardSignature(
            response: makeResponse(cardSignature: nil),
            cardPublicKey: cardKeyPair.publicKey,
            firmwareVersion: .walletOwnershipConfirmationAvailable,
            walletPublicKey: walletKeyPair.publicKey
        )

        XCTAssertTrue(isValid)
    }

    func testExpectedSignatureAbsentFailsClosed() throws {
        // [REDACTED_INFO]: the signature was requested (COS 2.01+, mode != none) but the card returned none.
        // Fail closed instead of accepting an unverified response.
        for mode in [AttestWalletKeyTask.ConfirmationMode.static, .dynamic] {
            let isValid = try makeTask(confirmationMode: mode).verifyCardSignature(
                response: makeResponse(cardSignature: nil),
                cardPublicKey: cardKeyPair.publicKey,
                firmwareVersion: .walletOwnershipConfirmationAvailable,
                walletPublicKey: walletKeyPair.publicKey
            )

            XCTAssertFalse(isValid)
        }
    }

    func testLegacyFirmwareAbsentSignatureIsAccepted() throws {
        // On COS < 2.01 the signature is never requested (see the gate in `serialize`),
        // so its absence is expected in any confirmation mode.
        for mode in [AttestWalletKeyTask.ConfirmationMode.static, .dynamic] {
            let isValid = try makeTask(confirmationMode: mode).verifyCardSignature(
                response: makeResponse(cardSignature: nil),
                cardPublicKey: cardKeyPair.publicKey,
                firmwareVersion: FirmwareVersion(major: 1, minor: 0),
                walletPublicKey: walletKeyPair.publicKey
            )

            XCTAssertTrue(isValid)
        }
    }

    func testDynamicModeWithoutPublicKeySaltFailsClosed() throws {
        // Downgrade guard: dynamic was requested, but the response carries no `publicKeySalt`. Verifying
        // it against a static message would let a previously recorded static signature pass.
        let staticSignature = try sign(walletKeyPair.publicKey)

        let isValid = try makeTask(confirmationMode: .dynamic).verifyCardSignature(
            response: makeResponse(cardSignature: staticSignature),
            cardPublicKey: cardKeyPair.publicKey,
            firmwareVersion: .walletOwnershipConfirmationAvailable,
            walletPublicKey: walletKeyPair.publicKey
        )

        XCTAssertFalse(isValid)
    }

    func testValidDynamicSignatureIsAccepted() throws {
        let signature = try sign(walletKeyPair.publicKey + challenge + publicKeySalt)

        let isValid = try makeTask(confirmationMode: .dynamic).verifyCardSignature(
            response: makeResponse(cardSignature: signature, publicKeySalt: publicKeySalt),
            cardPublicKey: cardKeyPair.publicKey,
            firmwareVersion: .walletOwnershipConfirmationAvailable,
            walletPublicKey: walletKeyPair.publicKey
        )

        XCTAssertTrue(isValid)
    }

    func testValidStaticSignatureIsAccepted() throws {
        // Static mode: the signed message is just the wallet public key, with no challenge/salt binding.
        let signature = try sign(walletKeyPair.publicKey)

        let isValid = try makeTask(confirmationMode: .static).verifyCardSignature(
            response: makeResponse(cardSignature: signature),
            cardPublicKey: cardKeyPair.publicKey,
            firmwareVersion: .walletOwnershipConfirmationAvailable,
            walletPublicKey: walletKeyPair.publicKey
        )

        XCTAssertTrue(isValid)
    }

    func testStaticSignatureWithInjectedSaltIsRejected() throws {
        // A salt injected into a static response lengthens the recomputed message,
        // so the static signature no longer matches.
        let signature = try sign(walletKeyPair.publicKey)

        let isValid = try makeTask(confirmationMode: .static).verifyCardSignature(
            response: makeResponse(cardSignature: signature, publicKeySalt: publicKeySalt),
            cardPublicKey: cardKeyPair.publicKey,
            firmwareVersion: .walletOwnershipConfirmationAvailable,
            walletPublicKey: walletKeyPair.publicKey
        )

        XCTAssertFalse(isValid)
    }

    func testTamperedSignatureIsRejected() throws {
        var tampered = try sign(walletKeyPair.publicKey + challenge + publicKeySalt)
        tampered[0] ^= 0xFF

        let isValid = try makeTask(confirmationMode: .dynamic).verifyCardSignature(
            response: makeResponse(cardSignature: tampered, publicKeySalt: publicKeySalt),
            cardPublicKey: cardKeyPair.publicKey,
            firmwareVersion: .walletOwnershipConfirmationAvailable,
            walletPublicKey: walletKeyPair.publicKey
        )

        XCTAssertFalse(isValid)
    }

    func testValidDynamicSignatureWithWalletStatusIsAccepted() throws {
        let status = Card.Wallet.Status.loaded
        let signature = try sign(walletKeyPair.publicKey + challenge + publicKeySalt + status.rawValue.byte)

        let isValid = try makeTask(confirmationMode: .dynamic).verifyCardSignature(
            response: makeResponse(cardSignature: signature, publicKeySalt: publicKeySalt, walletStatus: status),
            cardPublicKey: cardKeyPair.publicKey,
            firmwareVersion: .walletOwnershipConfirmationAvailable,
            walletPublicKey: walletKeyPair.publicKey
        )

        XCTAssertTrue(isValid)
    }

    func testTamperedWalletStatusIsRejected() throws {
        // The signature covers `loaded`, but the response claims `empty` — the recomputed message
        // differs, so a swapped status must fail verification.
        let signedStatus = Card.Wallet.Status.loaded
        let signature = try sign(walletKeyPair.publicKey + challenge + publicKeySalt + signedStatus.rawValue.byte)

        let isValid = try makeTask(confirmationMode: .dynamic).verifyCardSignature(
            response: makeResponse(cardSignature: signature, publicKeySalt: publicKeySalt, walletStatus: .empty),
            cardPublicKey: cardKeyPair.publicKey,
            firmwareVersion: .walletOwnershipConfirmationAvailable,
            walletPublicKey: walletKeyPair.publicKey
        )

        XCTAssertFalse(isValid)
    }
}

private extension AttestWalletKeyTaskTests {
    func makeTask(confirmationMode: AttestWalletKeyTask.ConfirmationMode) -> AttestWalletKeyTask {
        AttestWalletKeyTask(
            walletPublicKey: walletKeyPair.publicKey,
            challenge: challenge,
            confirmationMode: confirmationMode
        )
    }

    func makeResponse(
        cardSignature: Data?,
        publicKeySalt: Data? = nil,
        walletStatus: Card.Wallet.Status? = nil
    ) -> AttestWalletKeyResponse {
        AttestWalletKeyResponse(
            cardId: "CB42000000005343",
            salt: Data(repeating: 7, count: 16),
            walletSignature: Data(),
            challenge: challenge,
            cardSignature: cardSignature,
            publicKeySalt: publicKeySalt,
            walletStatus: walletStatus,
            counter: nil
        )
    }

    func sign(_ message: Data) throws -> Data {
        try Secp256k1Utils().sign(message, with: cardKeyPair.privateKey)
    }
}
