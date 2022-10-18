//
//  AccessCodeRepository.swift
//  TangemSdk
//
//  Created by Andrey Chukavin on 13.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

@available(iOS 13.0, *)
public class AccessCodeRepository {
    var isEmpty: Bool {
        getCards().isEmpty
    }
    
    private let storage: Storage = .init()
    private let secureStorage: SecureStorage = .init()
    private let biometricsStorage: BiometricsStorage  = .init()
    private var accessCodes: [String: Data] = .init()
    
    public init() {
        if !storage.bool(forKey: .hasClearedAccessCodeRepoOnLaunch) {
            clear()
            storage.set(boolValue: true, forKey: .hasClearedAccessCodeRepoOnLaunch)
        }
    }
    
    deinit {
        Log.debug("AccessCodeRepository deinit")
    }
    
    public func save(_ accessCode: Data, for cardIds: [String]) -> Result<Void, TangemSdkError> {
        guard BiometricsUtil.isAvailable else {
            return .failure(.biometricsUnavailable)
        }
        
        guard updateCodesIfNeeded(with: accessCode, for: cardIds) else {
            return .success(()) //Nothing changed. Return
        }
        
        do {
            for cardId in cardIds {
                let storageKey = SecureStorageKey.accessCode(for: cardId)
                
                if try getCards().contains(cardId) {
                    try biometricsStorage.delete(storageKey)
                }
                
                let result = biometricsStorage.store(accessCode, forKey: storageKey)
                
                if case .failure(let error) = result {
                    return .failure(error)
                }
            }

            self.saveCards()
            return .success(())
        } catch {
            Log.error(error)
            return .failure(error.toTangemSdkError())
        }
    }
    
    public func save(_ accessCode: Data, for cardId: String) -> Result<Void, TangemSdkError> {
        return save(accessCode, for: [cardId])
    }
    
    public func deleteAccessCode(for cardIds: [String]) -> Result<Void, TangemSdkError> {
        do {
            let savedCardIds = getCards()
            for cardId in cardIds {
                guard savedCardIds.contains(cardId) else { continue }
                
                try biometricsStorage.delete(SecureStorageKey.accessCode(for: cardId))
            }
            return .success(())
        } catch {
            Log.error(error)
            return .failure(error.toTangemSdkError())
        }
    }
    
    public func clear() {
        do {
            for cardId in getCards() {
                try biometricsStorage.delete(SecureStorageKey.accessCode(for: cardId))
            }
            try secureStorage.delete(.cardsWithSavedCodes)
        } catch {
            Log.error(error)
        }
    }
    
    func contains(_ cardId: String) -> Bool {
        let savedCards = getCards()
        return savedCards.contains(cardId)
    }
    
    func unlock(localizedReason: String, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        guard BiometricsUtil.isAvailable else {
            completion(.failure(.biometricsUnavailable))
            return
        }
        
        self.accessCodes = [:]
        
        BiometricsUtil.requestAccess(localizedReason: localizedReason) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                Log.error(error)
                completion(.failure(error))
            case .success(let context):
                var fetchedAccessCodes: [String: Data] = [:]
                
                for cardId in self.getCards() {
                    let result = self.biometricsStorage.get(SecureStorageKey.accessCode(for: cardId), context: context)
                    
                    switch result {
                    case .success(let data):
                        fetchedAccessCodes[cardId] = data
                    case .failure(let error):
                        Log.error(error)
                        completion(.failure(error))
                        return
                    }
                }

                self.accessCodes = fetchedAccessCodes
                completion(.success(()))
            }
        }
    }
    
    func lock() {
        accessCodes = .init()
    }
    
    func fetch(for cardId: String) -> Data? {
        return accessCodes[cardId]
    }
    
    private func updateCodesIfNeeded(with accessCode: Data, for cardIds: [String]) -> Bool {
        var hasChanges: Bool = false
        
        for cardId in cardIds {
            let existingCode = accessCodes[cardId]
            
            if existingCode == accessCode {
                continue //We already know this code. Ignoring
            }
            
            //We found default code
            if accessCode == UserCodeType.accessCode.defaultValue.sha256() {
                if existingCode == nil {
                    continue //Ignore default code
                } else {
                    accessCodes[cardId] = nil //User deleted the code. We should update the storage
                    hasChanges = true
                }
            } else {
                accessCodes[cardId] = accessCode //Save a new code
                hasChanges = true
            }
        }
        
        return hasChanges
    }
    
    private func getCards() -> Set<String> {
        if let data = try? secureStorage.get(.cardsWithSavedCodes) {
            return (try? JSONDecoder().decode(Set<String>.self, from: data)) ?? []
        }
        
        return []
    }
    
    private func saveCards() {
        if let data = try? JSONEncoder().encode(Set(accessCodes.keys)) {
            try? secureStorage.store(data, forKey: .cardsWithSavedCodes)
        }
    }
}
