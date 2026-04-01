//
//  CardAccessTokensRepository.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20/02/2026.
//

import Foundation
import LocalAuthentication

class CardAccessTokensRepository {
    var isEmpty: Bool {
        let cards = try? getCards()
        return cards?.isEmpty ?? true
    }

    private let storage: Storage = .init()
    private let secureStorage = SecureStorage()
    private let secureEnclave = SecureEnclaveService()
    private let biometricsStorage = BiometricsStorage()
    private let biometricsSecureEnclave = BiometricsSecureEnclaveService()
    private var tokens: [String: CardAccessTokens] = .init()

    public init() {
        if !storage.bool(forKey: .hasClearedCardAccessTokensRepoOnFirstLaunch) {
            clear()
            storage.set(boolValue: true, forKey: .hasClearedCardAccessTokensRepoOnFirstLaunch)
        }
    }

    deinit {
        Log.debug("CardAccessTokensRepository deinit")
    }

    func save(_ cardAccessTokens: CardAccessTokens, for cardIds: [String]) throws {
        guard BiometricsUtil.isAvailable else {
            throw TangemSdkError.biometricsUnavailable
        }

        var savedCardIds = try getCards()

        for cardId in cardIds {
            do {
                let storageKey = SecureStorageKey.cardAccessTokens(for: cardId)
                let encryptionKey = SecureStorageKey.cardAccessTokensEncryptionKey(for: cardId)

                biometricsSecureEnclave.deleteKey(tag: encryptionKey)
                try? biometricsStorage.delete(storageKey)

                var data = try JSONEncoder().encode(cardAccessTokens)
                let encryptedData = try biometricsSecureEnclave.encryptData(
                    data,
                    keyTag: encryptionKey,
                    context: nil
                )
                data.zeroOut()

                try biometricsStorage.store(encryptedData, forKey: storageKey)

                savedCardIds.insert(cardId)
                tokens[cardId] = cardAccessTokens
            } catch {
                Log.debug("Card access tokens error for cardId: \(cardId)")
            }
        }

        try saveCards(cardIds: savedCardIds)
        Log.debug("Card access tokens saved successfully")
    }

    func save(_ cardAccessTokens: CardAccessTokens, for cardId: String) throws {
        try save(cardAccessTokens, for: [cardId])
    }

    func deleteTokens(for cardIds: [String]) throws {
        if cardIds.isEmpty {
            return
        }

        var savedCardIds = try getCards()
        for cardId in cardIds {
            guard savedCardIds.contains(cardId) else {
                continue
            }

            let storageKey = SecureStorageKey.cardAccessTokens(for: cardId)
            let encryptionKey = SecureStorageKey.cardAccessTokensEncryptionKey(for: cardId)

            biometricsSecureEnclave.deleteKey(tag: encryptionKey)
            try? biometricsStorage.delete(storageKey)
            savedCardIds.remove(cardId)
            tokens[cardId] = nil
        }

        try saveCards(cardIds: savedCardIds)
        Log.debug("Card access tokens deletion completed successfully")
    }

    func clear() {
        Log.debug("Clear CardAccessTokensRepository")
        do {
            let cardIds = try getCards()
            try deleteTokens(for: Array(cardIds))
        } catch {
            Log.error(error)
        }
    }

    func contains(_ cardId: String) -> Bool {
        do {
            let savedCards = try getCards()
            return savedCards.contains(cardId)
        } catch {
            Log.error(error)
            return false
        }
    }

    func unlock(context: LAContext) throws {
        tokens = [:]
        Log.debug("Start unlocking card access tokens with provided context")

        var fetchedTokens: [String: CardAccessTokens] = [:]

        for cardId in try getCards() {
            let storageKey = SecureStorageKey.cardAccessTokens(for: cardId)
            let encryptionKey = SecureStorageKey.cardAccessTokensEncryptionKey(for: cardId)

            do {
                if let encryptedData = try biometricsStorage.get(storageKey, context: context) {
                    var data = try biometricsSecureEnclave.decryptData(
                        encryptedData,
                        keyTag: encryptionKey,
                        context: context
                    )
                    defer {
                        data.zeroOut()
                    }

                    let cardAccessTokens = try JSONDecoder().decode(CardAccessTokens.self, from: data)
                    fetchedTokens[cardId] = cardAccessTokens
                }
            } catch {
                Log.debug("Failed to unlock card access tokens for cardId: \(cardId). Error: \(error)")
            }
        }

        tokens = fetchedTokens
        try saveCards(cardIds: Set(fetchedTokens.keys))
        Log.debug("Card access tokens unlocked successfully")
    }

    func lock() {
        Log.debug("Lock the card access tokens repo")
        tokens = .init()
    }

    func fetch(for cardId: String) -> CardAccessTokens? {
        return tokens[cardId]
    }

    private func getCards() throws -> Set<String> {
        guard let encryptedData = try secureStorage.get(.cardsWithSavedAccessTokens) else {
            return []
        }

        let data = try secureEnclave.decryptData(encryptedData, storageKey: .cardsWithSavedAccessTokensEncryptionKey)
        let decoded = try JSONDecoder().decode(Set<String>.self, from: data)
        return decoded
    }

    private func saveCards(cardIds: Set<String>) throws {
        let data = try JSONEncoder().encode(cardIds)
        let encryptedData = try secureEnclave.encryptData(data, storageKey: .cardsWithSavedAccessTokensEncryptionKey)
        try secureStorage.store(encryptedData, forKey: .cardsWithSavedAccessTokens)
    }
}
