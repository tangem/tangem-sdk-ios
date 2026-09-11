//
//  TangemSdkSecureStorageCleaner.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Wipes every Keychain item the SDK persists, except the backup payload
/// (the `backupData` key). Intended to be called by the host app
/// once on its first launch to reset any state left over from a reinstall.
public struct TangemSdkSecureStorageCleaner {
    private let secureStorage = SecureStorage()
    private let secureEnclave = SecureEnclaveService()
    private let accessCodeRepository = AccessCodeRepository()
    private let cardAccessTokensRepository = CardAccessTokensRepository()

    public init() {}

    public func clean() {
        // Per-card access codes / tokens together with their Secure Enclave keys.
        // Must run before the card-set items and their encryption keys are deleted,
        // otherwise the repositories can no longer enumerate the stored card ids.
        accessCodeRepository.clear()
        cardAccessTokensRepository.clear()

        deleteGenericPasswords()
        deleteSecureEnclaveKeys()
    }

    private func deleteGenericPasswords() {
        let keys: [SecureStorageKey] = [
            .terminalPrivateKey,
            .terminalPublicKey,
            .attestedCards,
            .onlineAttestationResponses,
            .cardsWithSavedCodes,
            .cardsWithSavedAccessTokens,
        ]

        for key in keys {
            do {
                try secureStorage.delete(key)
            } catch {
                Log.error(error)
            }
        }
    }

    private func deleteSecureEnclaveKeys() {
        let tags: [SecureStorageKey] = [
            .attestedCardsEncryptionKey,
            .onlineAttestationResponsesEncryptionKey,
            .cardsWithSavedCodesEncryptionKey,
            .cardsWithSavedAccessTokensEncryptionKey,
        ]

        for tag in tags {
            secureEnclave.deleteKey(tag: tag.rawValue)
        }
    }
}
