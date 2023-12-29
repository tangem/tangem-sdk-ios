//
//  StartBackupCardLinkingTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
final class StartBackupCardLinkingTask: CardSessionRunnable {
    var shouldAskForAccessCode: Bool { false }

    private let primaryCard: PrimaryCard
    private let addedBackupCards: [String]
    private let skipCompatibilityChecks: Bool
    private var linkingCommand: StartBackupCardLinkingCommand? = nil

    init(primaryCard: PrimaryCard, addedBackupCards: [String], skipCompatibilityChecks: Bool = false) {
        self.primaryCard = primaryCard
        self.addedBackupCards = addedBackupCards
        self.skipCompatibilityChecks = skipCompatibilityChecks
    }

    deinit {
        Log.debug("StartBackupCardLinkingTask deinit")
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<BackupCard>) {
        if session.environment.config.handleErrors {
            guard let card = session.environment.card else {
                completion(.failure(.missingPreflightRead))
                return
            }

            let primaryWalletCurves = Set(primaryCard.walletCurves)
            let backupCardSupportedCurves = Set(card.supportedCurves)

            if !skipCompatibilityChecks {
                if card.issuer.publicKey != primaryCard.issuer.publicKey {
                    completion(.failure(.backupFailedWrongIssuer))
                    return
                }

                if card.settings.isHDWalletAllowed != primaryCard.isHDWalletAllowed {
                    completion(.failure(.backupFailedHDWalletSettings))
                    return
                }

                if !isBatchIdCompatible(card.batchId) {
                    completion(.failure(.backupFailedIncompatibleBatch))
                    return
                }

                if let firmwareVersion = primaryCard.firmwareVersion, firmwareVersion != card.firmwareVersion {
                    completion(.failure(.backupFailedIncompatibleFirmware))
                    return
                }
            }

            if let isKeysImportAllowed = primaryCard.isKeysImportAllowed, isKeysImportAllowed != card.settings.isKeysImportAllowed {
                completion(.failure(.backupFailedKeysImportSettings))
                return
            }

            if !primaryWalletCurves.isSubset(of: backupCardSupportedCurves) {
                completion(.failure(.backupFailedNotEnoughCurves))
                return
            }

            if primaryCard.existingWalletsCount > card.settings.maxWalletsCount {
                completion(.failure(.backupFailedNotEnoughWallets))
                return
            }

            if card.cardId.lowercased() == primaryCard.cardId.lowercased() {
                completion(.failure(.backupCardRequired))
                return
            }

            if addedBackupCards.contains(card.cardId) {
                completion(.failure(.backupCardAlreadyAdded))
                return
            }
        }

        linkingCommand = StartBackupCardLinkingCommand(primaryCardLinkingKey: primaryCard.linkingKey)
        linkingCommand!.run(in: session, completion: completion)
    }

    private func isBatchIdCompatible(_ batchId: String) -> Bool {
        guard let primaryCardBatchId = primaryCard.batchId?.uppercased() else {
            return true //We found the old interrupted backup. Skip this check.
        }

        let backupCardBatchId = batchId.uppercased()

        if backupCardBatchId == primaryCardBatchId {
            return true
        }

        if BatchId.isDetached(backupCardBatchId) || BatchId.isDetached(primaryCardBatchId) {
            return false
        }

        return true
    }
}

public struct BatchId {
    private static let detached: [String] = ["AC01", "AC02", "CB95"]

    public static func isDetached(_ batchId: String) -> Bool {
        BatchId.detached.contains(batchId)
    }
}
