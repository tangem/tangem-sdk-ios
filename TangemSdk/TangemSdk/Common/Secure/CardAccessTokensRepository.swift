//
//  CardAccessTokensRepository.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20/02/2026.
//

import Foundation

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
            let storageKey = SecureStorageKey.cardAccessTokens(for: cardId)
            let encryptionKey = SecureStorageKey.cardAccessTokensEncryptionKey(for: cardId)

            biometricsSecureEnclave.deleteKey(tag: encryptionKey)
            try? biometricsStorage.delete(storageKey)

            let data = try JSONEncoder().encode(cardAccessTokens)
            let encryptedData = try biometricsSecureEnclave.encryptData(
                data,
                keyTag: encryptionKey,
                context: nil
            )

            try biometricsStorage.store(encryptedData, forKey: storageKey)

            savedCardIds.insert(cardId)
            tokens[cardId] = cardAccessTokens
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

    func unlock(localizedReason: String, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        guard BiometricsUtil.isAvailable else {
            completion(.failure(.biometricsUnavailable))
            return
        }

        self.tokens = [:]
        Log.debug("Start unlocking card access tokens with biometrics")

        BiometricsUtil.requestAccess(localizedReason: localizedReason) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                Log.error(error)
                completion(.failure(error))
            case .success(let context):
                Log.debug("Card access tokens storage was unlocked successfully")
                do {
                    var fetchedTokens: [String: CardAccessTokens] = [:]

                    for cardId in try self.getCards() {
                        let storageKey = SecureStorageKey.cardAccessTokens(for: cardId)
                        let encryptionKey = SecureStorageKey.cardAccessTokensEncryptionKey(for: cardId)

                        if let encryptedData = try self.biometricsStorage.get(storageKey, context: context) {
                            let data = try self.biometricsSecureEnclave.decryptData(
                                encryptedData,
                                keyTag: encryptionKey,
                                context: context
                            )

                            let cardAccessTokens = try JSONDecoder().decode(CardAccessTokens.self, from: data)
                            fetchedTokens[cardId] = cardAccessTokens
                        }
                    }

                    self.tokens = fetchedTokens
                    try self.saveCards(cardIds: Set(fetchedTokens.keys))
                    completion(.success(()))
                } catch {
                    Log.error(error)
                    completion(.failure(error.toTangemSdkError()))
                }
            }
        }
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
