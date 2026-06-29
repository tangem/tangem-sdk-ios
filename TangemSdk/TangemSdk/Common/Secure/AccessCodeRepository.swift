//
//  AccessCodeRepository.swift
//  TangemSdk
//
//  Created by Andrey Chukavin on 13.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication

public class AccessCodeRepository {
    var isEmpty: Bool {
        let cards = try? getCards()
        return cards?.isEmpty ?? true
    }

    private let storage: Storage = .init()
    private let secureStorage = SecureStorage()
    private let secureEnclave = SecureEnclaveService()
    private let biometricsStorage = BiometricsStorage()
    private let biometricsSecureEnclave = BiometricsSecureEnclaveService()
    private var accessCodes: [String: Data] = .init()

    public init() {
        if !storage.bool(forKey: .hasClearedAccessCodeRepoOnFirstLaunch) {
            clear()
            storage.set(boolValue: true, forKey: .hasClearedAccessCodeRepoOnFirstLaunch)
        }
    }

    deinit {
        Log.debug("AccessCodeRepository deinit")
    }

    public func save(_ accessCode: Data, for cardIds: [String], firmwareVersion: FirmwareVersion) throws {
        guard firmwareVersion < .v8 else {
            throw TangemSdkError.notSupportedFirmwareVersion
        }

        guard BiometricsUtil.isAvailable else {
            throw TangemSdkError.biometricsUnavailable
        }

        guard updateCodesIfNeeded(with: accessCode, for: cardIds) else {
            Log.debug("Skip saving")
            return // Nothing changed. Return
        }

        var savedCardIds = try getCards()

        for cardId in cardIds {
            do {
                let storageKey = SecureStorageKey.accessCode(for: cardId)
                let encryptionKey = SecureStorageKey.accessCodeEncryptionKey(for: cardId)

                biometricsSecureEnclave.deleteKey(tag: encryptionKey)
                try? biometricsStorage.delete(storageKey)

                let encryptedAccessCode = try biometricsSecureEnclave.encryptData(
                    accessCode,
                    keyTag: encryptionKey,
                    context: nil
                )

                try biometricsStorage.store(encryptedAccessCode, forKey: storageKey)

                savedCardIds.insert(cardId)
            } catch {
                Log.debug("Access codes repository error for cardId: \(cardId)")
            }
        }

        try saveCards(cardIds: savedCardIds)
        Log.debug("The saving was completed successfully")
    }

    public func save(_ accessCode: Data, for cardId: String, firmwareVersion: FirmwareVersion) throws {
        try save(accessCode, for: [cardId], firmwareVersion: firmwareVersion)
    }

    public func deleteAccessCode(for cardIds: [String]) throws {
        if cardIds.isEmpty {
            return
        }

        var savedCardIds = try getCards()
        for cardId in cardIds {
            guard savedCardIds.contains(cardId) else {
                continue
            }

            let storageKey = SecureStorageKey.accessCode(for: cardId)
            let encryptionKey = SecureStorageKey.accessCodeEncryptionKey(for: cardId)

            biometricsSecureEnclave.deleteKey(tag: encryptionKey)
            try? biometricsStorage.delete(storageKey)
            savedCardIds.remove(cardId)
        }
        try saveCards(cardIds: savedCardIds)
        Log.debug("The deletion was completed successfully")
    }

    public func clear() {
        Log.debug("Clear AccessCodeRepository")
        do {
            let cardIds = try getCards()
            try deleteAccessCode(for: Array(cardIds))
        } catch {
            Log.error(error)
        }
    }

    func contains(_ cardId: String) -> Bool {
        do {
            let savedCards = try getCards()
            let contains = savedCards.contains(cardId)
            return contains
        } catch {
            Log.error(error)
            return false
        }
    }

    func unlock(context: LAContext) throws {
        accessCodes = [:]
        Log.debug("Start unlocking access codes with provided context")

        var fetchedAccessCodes: [String: Data] = [:]

        for cardId in try getCards() {
            let storageKey = SecureStorageKey.accessCode(for: cardId)
            let encryptionKey = SecureStorageKey.accessCodeEncryptionKey(for: cardId)
            do {
                if let encryptedAccessCode = try biometricsStorage.get(storageKey, context: context) {
                    do {
                        let accessCode = try biometricsSecureEnclave.decryptData(
                            encryptedAccessCode,
                            keyTag: encryptionKey,
                            context: context
                        )

                        fetchedAccessCodes[cardId] = accessCode
                    } catch SecureEnclaveError.decryptionFailed {
                        // use old unencrypted data for backward compatibility
                        if encryptedAccessCode.count == 32 {
                            fetchedAccessCodes[cardId] = encryptedAccessCode
                        }
                    }
                }
            } catch {
                Log.debug("Failed to unlock access codes for cardId: \(cardId). Error: \(error)")
            }
        }

        accessCodes = fetchedAccessCodes
        try saveCards(cardIds: Set(fetchedAccessCodes.keys)) // Actualize all the cards. E.g. if biometrics was changed.
        Log.debug("Access codes unlocked successfully")
    }

    func lock() {
        Log.debug("Lock the access codes repo")
        accessCodes = .init()
    }

    func fetch(for cardId: String) -> Data? {
        let code = accessCodes[cardId]
        return code
    }

    private func updateCodesIfNeeded(with accessCode: Data, for cardIds: [String]) -> Bool {
        var hasChanges = false

        for cardId in cardIds {
            let existingCode = accessCodes[cardId]

            if let existingCode, CryptoUtils.secureCompare(existingCode, accessCode) {
                Log.debug("We already know this code. Ignoring.")
                continue // We already know this code. Ignoring
            }

            // We found default code
            if CryptoUtils.secureCompare(accessCode, UserCodeType.accessCode.defaultValue.getSHA256()) {
                if existingCode == nil {
                    Log.debug("Ignore the default code")
                    continue // Ignore default code
                } else {
                    Log.debug("User deleted the code. We should update the storage.")
                    accessCodes[cardId] = nil // User deleted the code. We should update the storage.
                    hasChanges = true
                }
            } else {
                Log.debug("Save a new code")
                accessCodes[cardId] = accessCode // Save a new code
                hasChanges = true
            }
        }

        return hasChanges
    }

    private func getCards() throws -> Set<String> {
        guard let encryptedData = try secureStorage.get(.cardsWithSavedCodes) else {
            return []
        }

        do {
            let data = try secureEnclave.decryptData(encryptedData, storageKey: .cardsWithSavedCodesEncryptionKey)
            let decoded = try JSONDecoder().decode(Set<String>.self, from: data)
            return decoded
        } catch {
            // try decode old unencrypted data for backward compatibility
            let decoded = try JSONDecoder().decode(Set<String>.self, from: encryptedData)
            return decoded
        }
    }

    private func saveCards(cardIds: Set<String>) throws {
        let data = try JSONEncoder().encode(cardIds)
        let encryptedData = try secureEnclave.encryptData(data, storageKey: .cardsWithSavedCodesEncryptionKey)
        try secureStorage.store(encryptedData, forKey: .cardsWithSavedCodes)
    }
}
