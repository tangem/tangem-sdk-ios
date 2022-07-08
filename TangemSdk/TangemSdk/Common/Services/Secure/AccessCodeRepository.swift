//
//  AccessCodeRepository.swift
//  TangemSdk
//
//  Created by Andrey Chukavin on 13.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

@available(iOS 13.0, *)
class AccessCodeRepository {
    private let secureStorage: SecureStorage = .init()
    private let biometricsStorage: BiometricsStorage  = .init()
    private var accessCodes: [String: Data] = .init()
    
    deinit {
        Log.debug("AccessCodeRepository deinit")
    }
    
    func hasItems(for cardId: String?) -> Bool {
        let savedCards = getCards()
        
        if savedCards.isEmpty {
            return false
        }
        
        if let cardId = cardId {
            return savedCards.contains(cardId)
        }
        
        return true
    }
    
    func unlock(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        guard BiometricsUtil.isAvailable else {
            completion(.failure(.biometricsUnavailable))
            return
        }
        
        accessCodes = .init()
        
        biometricsStorage.get(account: .accessCodes) { result in
            switch result {
            case .success(let data):
                if let data = data,
                   let codes = try? JSONDecoder().decode([String: Data].self, from: data) {
                    self.accessCodes = codes
                }
                completion(.success(()))
            case .failure(let error):
                Log.error(error)
                completion(.failure(error))
            }
        }
    }
    
    func lock() {
        accessCodes = .init()
    }
    
    func fetch(for cardId: String) -> Data? {
        return accessCodes[cardId]
    }
    
    func save(_ accessCode: Data, for cardId: String, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        guard BiometricsUtil.isAvailable else {
            completion(.failure(.biometricsUnavailable))
            return
        }

        let existingCode = accessCodes[cardId]

        if existingCode == accessCode {
            completion(.success(())) //We already know this code. Ignoring
            return
        }
        
        //We found default code
        if accessCode == UserCodeType.accessCode.defaultValue.sha256() {
            if existingCode == nil {
                completion(.success(())) //Ignore default code
                return
            } else {
                accessCodes[cardId] = nil //User deleted the code. We should update the storage
            }
        } else {
            accessCodes[cardId] = accessCode //Save a new code
        }
        
        do {
            let data = try JSONEncoder().encode(accessCodes)
            
            biometricsStorage.store(object: data, account: .accessCodes) { result in
                switch result {
                case .success:
                    self.saveCards()
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            Log.error(error)
            completion(.failure(error.toTangemSdkError()))
        }
    }
    
    func removeAll() {
        do {
            try biometricsStorage.delete(account: .accessCodes)
            try secureStorage.delete(account: .cardsWithSavedCodes)
        } catch {
            Log.error(error)
        }
    }
    
    // MARK: Helper save/get methods
    private func getCards() -> [String] {
        if let data = try? secureStorage.get(account: .cardsWithSavedCodes) {
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        
        return []
    }
    
    private func saveCards() {
        if let data = try? JSONEncoder().encode(Array(accessCodes.keys)) {
            try? secureStorage.store(object: data, account: .cardsWithSavedCodes)
        }
    }
}
