//
//  CardModelTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 16/03/2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class CardModelTests: XCTestCase {
    // MARK: - Card JSON fixture decoding

    func testDecodeCardFromFixture() throws {
        let card = try decodeCardFromFixture()

        XCTAssertEqual(card.cardId, "CB79000000018201")
        XCTAssertEqual(card.batchId, "CB79")
        XCTAssertEqual(card.firmwareVersion.major, 4)
        XCTAssertEqual(card.firmwareVersion.minor, 12)
        XCTAssertEqual(card.firmwareVersion.type, .release)
        XCTAssertEqual(card.manufacturer.name, "TANGEM")
        XCTAssertEqual(card.issuer.name, "TANGEM AG")
        XCTAssertTrue(card.isAccessCodeSet)
        XCTAssertEqual(card.isPasscodeSet, true)
        XCTAssertEqual(card.linkedTerminalStatus, .none)
    }

    func testDecodeCardSupportedCurves() throws {
        let card = try decodeCardFromFixture()

        XCTAssertEqual(card.supportedCurves.count, 3)
        XCTAssertTrue(card.supportedCurves.contains(.secp256k1))
        XCTAssertTrue(card.supportedCurves.contains(.ed25519))
        XCTAssertTrue(card.supportedCurves.contains(.secp256r1))
    }

    func testDecodeCardWallets() throws {
        let card = try decodeCardFromFixture()

        XCTAssertEqual(card.wallets.count, 3)
        XCTAssertEqual(card.wallets[0].curve, .ed25519)
        XCTAssertEqual(card.wallets[0].index, 0)
        XCTAssertFalse(card.wallets[0].hasBackup)
        XCTAssertEqual(card.wallets[1].curve, .secp256k1)
        XCTAssertEqual(card.wallets[2].curve, .secp256r1)
    }

    func testDecodeCardSettings() throws {
        let card = try decodeCardFromFixture()

        XCTAssertEqual(card.settings.securityDelay, 3000)
        XCTAssertEqual(card.settings.maxWalletsCount, 36)
        XCTAssertTrue(card.settings.isSettingPasscodeAllowed)
        XCTAssertFalse(card.settings.isSettingAccessCodeAllowed)
        XCTAssertTrue(card.settings.isHDWalletAllowed)
        XCTAssertTrue(card.settings.isBackupAllowed)
        XCTAssertTrue(card.settings.isKeysImportAllowed)
        XCTAssertFalse(card.settings.isBackupRequired)
    }

    func testDecodeCardBackupStatus() throws {
        let card = try decodeCardFromFixture()

        XCTAssertEqual(card.backupStatus, .noBackup)
    }

    func testDecodeCardAttestation() throws {
        let card = try decodeCardFromFixture()

        XCTAssertEqual(card.attestation.cardKeyAttestation, .verified)
        XCTAssertEqual(card.attestation.walletKeysAttestation, .verified)
        XCTAssertEqual(card.attestation.firmwareAttestation, .skipped)
        XCTAssertEqual(card.attestation.cardUniquenessAttestation, .skipped)
    }

    // MARK: - BackupStatus

    func testBackupStatusNoBackup() {
        let status = Card.BackupStatus.noBackup
        XCTAssertFalse(status.isActive)
        XCTAssertTrue(status.canBackup)
        XCTAssertEqual(status.linkedCardsCount, 0)
        XCTAssertEqual(status.backupCardsCount, 0)
    }

    func testBackupStatusCardLinked() {
        let status = Card.BackupStatus.cardLinked(cardsCount: 2)
        XCTAssertFalse(status.isActive)
        XCTAssertFalse(status.canBackup)
        XCTAssertEqual(status.linkedCardsCount, 2)
        XCTAssertEqual(status.backupCardsCount, 0)
    }

    func testBackupStatusActive() {
        let status = Card.BackupStatus.active(cardsCount: 3)
        XCTAssertTrue(status.isActive)
        XCTAssertFalse(status.canBackup)
        XCTAssertEqual(status.linkedCardsCount, 3)
        XCTAssertEqual(status.backupCardsCount, 3)
    }

    func testBackupStatusCodableRoundTrip() throws {
        let statuses: [Card.BackupStatus] = [
            .noBackup,
            .cardLinked(cardsCount: 2),
            .active(cardsCount: 3),
        ]

        for status in statuses {
            let data = try JSONEncoder.tangemSdkEncoder.encode(status)
            let decoded = try JSONDecoder.tangemSdkDecoder.decode(Card.BackupStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    // MARK: - BackupRawStatus

    func testBackupRawStatusIntValues() {
        XCTAssertEqual(Card.BackupRawStatus.noBackup.intValue, 0)
        XCTAssertEqual(Card.BackupRawStatus.cardLinked.intValue, 1)
        XCTAssertEqual(Card.BackupRawStatus.active.intValue, 2)
    }

    func testBackupRawStatusMakeFromInt() {
        XCTAssertEqual(Card.BackupRawStatus.make(from: 0), .noBackup)
        XCTAssertEqual(Card.BackupRawStatus.make(from: 1), .cardLinked)
        XCTAssertEqual(Card.BackupRawStatus.make(from: 2), .active)
        XCTAssertNil(Card.BackupRawStatus.make(from: 99))
    }

    // MARK: - Wallet.Status

    func testWalletStatusIsAvailable() {
        XCTAssertFalse(Card.Wallet.Status.empty.isAvailable)
        XCTAssertTrue(Card.Wallet.Status.loaded.isAvailable)
        XCTAssertFalse(Card.Wallet.Status.purged.isAvailable)
        XCTAssertTrue(Card.Wallet.Status.backedUp.isAvailable)
        XCTAssertFalse(Card.Wallet.Status.backedUpAndPurged.isAvailable)
        XCTAssertTrue(Card.Wallet.Status.imported.isAvailable)
        XCTAssertTrue(Card.Wallet.Status.backedUpImported.isAvailable)
        XCTAssertFalse(Card.Wallet.Status.emptyBackedUp.isAvailable)
    }

    func testWalletStatusIsBackedUp() {
        XCTAssertFalse(Card.Wallet.Status.empty.isBackedUp)
        XCTAssertFalse(Card.Wallet.Status.loaded.isBackedUp)
        XCTAssertTrue(Card.Wallet.Status.backedUp.isBackedUp)
        XCTAssertTrue(Card.Wallet.Status.backedUpAndPurged.isBackedUp)
        XCTAssertTrue(Card.Wallet.Status.backedUpImported.isBackedUp)
        XCTAssertFalse(Card.Wallet.Status.imported.isBackedUp)
    }

    func testWalletStatusIsImported() {
        XCTAssertFalse(Card.Wallet.Status.loaded.isImported)
        XCTAssertTrue(Card.Wallet.Status.imported.isImported)
        XCTAssertTrue(Card.Wallet.Status.backedUpImported.isImported)
        XCTAssertFalse(Card.Wallet.Status.backedUp.isImported)
    }

    // MARK: - LinkedTerminalStatus

    func testLinkedTerminalStatusDecoding() throws {
        let statuses: [Card.LinkedTerminalStatus] = [.current, .other, .none]

        for status in statuses {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(Card.LinkedTerminalStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    // MARK: - Helpers

    private func decodeCardFromFixture() throws -> Card {
        let data = try Bundle.readFileAsData(name: "Card", in: .root)
        return try JSONDecoder.tangemSdkDecoder.decode(Card.self, from: data)
    }
}
