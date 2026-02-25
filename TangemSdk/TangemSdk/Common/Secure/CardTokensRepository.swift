//
//  CardTokensRepository.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20/02/2026.
//

import Foundation

class CardTokensRepository {
    var isEmpty: Bool {
        let cards = try? getCards()
        return cards?.isEmpty ?? true
    }

    private let storage: Storage = .init()
    private let secureStorage = SecureStorage()
    private let secureEnclave = SecureEnclaveService()
    private let biometricsStorage = BiometricsStorage()
    private let biometricsSecureEnclave = BiometricsSecureEnclaveService()
    private var tokens: [String: CardTokens] = .init()

    public init() {
        if !storage.bool(forKey: .hasClearedCardTokensRepoOnFirstLaunch) {
            clear()
            storage.set(boolValue: true, forKey: .hasClearedCardTokensRepoOnFirstLaunch)
        }
    }

    deinit {
        Log.debug("CardTokensRepository deinit")
    }

    func save(_ cardTokens: CardTokens, for cardIds: [String]) throws {
        guard BiometricsUtil.isAvailable else {
            throw TangemSdkError.biometricsUnavailable
        }

        var savedCardIds = try getCards()

        for cardId in cardIds {
            let storageKey = SecureStorageKey.cardTokens(for: cardId)
            let encryptionKey = SecureStorageKey.cardTokensEncryptionKey(for: cardId)

            biometricsSecureEnclave.deleteKey(tag: encryptionKey)
            try? biometricsStorage.delete(storageKey)

            let data = try JSONEncoder().encode(cardTokens)
            let encryptedData = try biometricsSecureEnclave.encryptData(
                data,
                keyTag: encryptionKey,
                context: nil
            )

            try biometricsStorage.store(encryptedData, forKey: storageKey)

            savedCardIds.insert(cardId)
            tokens[cardId] = cardTokens
        }

        try saveCards(cardIds: savedCardIds)
        Log.debug("Card tokens saved successfully")
    }

    func save(_ cardTokens: CardTokens, for cardId: String) throws {
        try save(cardTokens, for: [cardId])
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

            let storageKey = SecureStorageKey.cardTokens(for: cardId)
            let encryptionKey = SecureStorageKey.cardTokensEncryptionKey(for: cardId)

            biometricsSecureEnclave.deleteKey(tag: encryptionKey)
            try? biometricsStorage.delete(storageKey)
            savedCardIds.remove(cardId)
            tokens[cardId] = nil
        }

        try saveCards(cardIds: savedCardIds)
        Log.debug("Card tokens deletion completed successfully")
    }

    func clear() {
        Log.debug("Clear CardTokensRepository")
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
        Log.debug("Start unlocking card tokens with biometrics")

        BiometricsUtil.requestAccess(localizedReason: localizedReason) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                Log.error(error)
                completion(.failure(error))
            case .success(let context):
                Log.debug("Card tokens storage was unlocked successfully")
                do {
                    var fetchedTokens: [String: CardTokens] = [:]

                    for cardId in try self.getCards() {
                        let storageKey = SecureStorageKey.cardTokens(for: cardId)
                        let encryptionKey = SecureStorageKey.cardTokensEncryptionKey(for: cardId)

                        if let encryptedData = try self.biometricsStorage.get(storageKey, context: context) {
                            let data = try self.biometricsSecureEnclave.decryptData(
                                encryptedData,
                                keyTag: encryptionKey,
                                context: context
                            )

                            let cardTokens = try JSONDecoder().decode(CardTokens.self, from: data)
                            fetchedTokens[cardId] = cardTokens
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
        Log.debug("Lock the card tokens repo")
        tokens = .init()
    }

    func fetch(for cardId: String) -> CardTokens? {
        return tokens[cardId]
    }

    private func getCards() throws -> Set<String> {
        guard let encryptedData = try secureStorage.get(.cardsWithSavedTokens) else {
            return []
        }

        let data = try secureEnclave.decryptData(encryptedData, storageKey: .cardsWithSavedTokensEncryptionKey)
        let decoded = try JSONDecoder().decode(Set<String>.self, from: data)
        return decoded
    }

    private func saveCards(cardIds: Set<String>) throws {
        let data = try JSONEncoder().encode(cardIds)
        let encryptedData = try secureEnclave.encryptData(data, storageKey: .cardsWithSavedTokensEncryptionKey)
        try secureStorage.store(encryptedData, forKey: .cardsWithSavedTokens)
    }
}
