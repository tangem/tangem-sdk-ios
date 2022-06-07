//
//  AccessCodeRepository.swift
//  TangemSdk
//
//  Created by Andrey Chukavin on 13.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import LocalAuthentication

public protocol AccessCodeRepository {
    func shouldAskForAuthentication(for cardId: String?) -> Bool
    func hasAccessToBiometricAuthentication() -> Bool
    func prepareAuthentication(for cardId: String?, completion: @escaping () -> Void)
    func fetchAccessCode(for cardId: String, completion: @escaping (Result<String, Error>) -> Void)
    func saveAccessCode(_ accessCode: String, for cardId: String, completion: @escaping (Result<Bool, Error>) -> Void)
    func removeAllAccessCodes()
}

@available(iOS 13.0, *)
public class DefaultAccessCodeRepository: AccessCodeRepository {
    public enum Errors: Error {
        case noBiometryAccess
        case noAccessCodeFound
    }
    
    private typealias CardIdList = Set<String>
    private typealias AccessCodeList = [String: String]
    
    private let secureStorage = SecureStorage()
    private let storage = Storage()
    private var context: LAContext?
    
    private let cardIdListKey = "card-id-list"
    private let accessCodeListKey = "access-code-list"
    #warning("TODO: l10n")
    private var touchIdReason: String {
        "Touch ID is needed BECAUSE"
    }
    private let authenticationPolicy: LAPolicy = .deviceOwnerAuthentication
    
    public init() {
        
    }
    
    public func shouldAskForAuthentication(for cardId: String?) -> Bool {
        guard askedForLocalAuthentication() else {
            return false
        }
        
        if let cardId = cardId {
            return hasAccessCode(for: cardId)
        } else {
            return hasAccessCodes()
        }
    }
    
    public func hasAccessToBiometricAuthentication() -> Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    public func hasAccessCode(for cardId: String) -> Bool {
        do {
            let cardIds = try cardIds()
            return cardIds.contains(cardId)
        } catch {
            print("Failed to get card ID list: \(error)")
            return false
        }
    }
    
    public func prepareAuthentication(for cardId: String?, completion: @escaping () -> Void) {
        guard shouldAskForAuthentication(for: cardId) else {
            completion()
            return
        }
        
        authenticate(context: LAContext()) { result in
            switch result {
            case .failure(let error):
                print("Failed to authenticate", error)
            case .success(let authenticatedContext):
                self.context = authenticatedContext
            }
            completion()
        }
    }
    
    public func fetchAccessCode(for cardId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let context = self.context else {
            completion(.failure(Errors.noBiometryAccess))
            return
        }
        
        authenticate(context: context) { result in
            if case let .failure(error) = result {
                completion(.failure(error))
                return
            }
            
            do {
                let accessCodes = try self.accessCodes(context: context)
                
                if let accessCode = accessCodes[cardId] {
                    completion(.success(accessCode))
                } else {
                    completion(.failure(Errors.noAccessCodeFound))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func saveAccessCode(_ accessCode: String, for cardId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let context = LAContext()
        authenticate(context: context) { result in
            if case let .failure(error) = result {
                completion(.failure(error))
                return
            }
            
            do {
                var accessCodes = try self.accessCodes(context: context)
                accessCodes[cardId] = accessCode
                try self.saveAccessCodes(accessCodes: accessCodes, context: context)
                
                var cardIds = try self.cardIds()
                cardIds.insert(cardId)
                try self.saveCardIds(cardIds: cardIds)
                
                completion(.success(true))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func removeAllAccessCodes() {
        do {
            try secureStorage.delete(account: cardIdListKey)
            try secureStorage.delete(account: accessCodeListKey)
        } catch {
            print("Failed to remove access codes: \(error)")
        }
    }
    
    private func authenticate(context: LAContext, completion: @escaping (Result<LAContext, Error>) -> Void) {
        var accessError: NSError?
        guard context.canEvaluatePolicy(authenticationPolicy, error: &accessError) else {
            print("No biometry access", accessError)
            if let accessError = accessError {
                completion(.failure(accessError))
            } else {
                completion(.failure(Errors.noBiometryAccess))
            }
            return
        }

        storage.set(boolValue: true, forKey: .askedForLocalAuthentication)
        
        context.evaluatePolicy(authenticationPolicy, localizedReason: touchIdReason) { success, authenticationError in
            if let authenticationError = authenticationError {
                completion(.failure(authenticationError))
                return
            }
            
            completion(.success(context))
        }
    }
    
    private func askedForLocalAuthentication() -> Bool {
        storage.bool(forKey: .askedForLocalAuthentication)
    }
    
    private func hasAccessCodes() -> Bool {
        do {
            let cardIds = try cardIds()
            return !cardIds.isEmpty
        } catch {
            print("Failed to get card ID list: \(error)")
            return false
        }
    }
    
    // MARK: Helper save/get methods
    
    private func cardIds() throws -> CardIdList {
        let data = try secureStorage.get(account: cardIdListKey) ?? Data()
        guard !data.isEmpty else {
            return CardIdList()
        }
        return try JSONDecoder().decode(CardIdList.self, from: data)
    }
    
    private func saveCardIds(cardIds: CardIdList) throws {
        let data = try JSONEncoder().encode(cardIds)
        try secureStorage.store(object: data, account: cardIdListKey, overwrite: true)
    }
    
    private func accessCodes(context: LAContext) throws -> AccessCodeList {
        let data = try secureStorage.get(account: accessCodeListKey, context: context) ?? Data()
        guard !data.isEmpty else {
            return AccessCodeList()
        }
        return try JSONDecoder().decode(AccessCodeList.self, from: data)
    }
    
    private func saveAccessCodes(accessCodes: AccessCodeList, context: LAContext) throws {
        let data = try JSONEncoder().encode(accessCodes)
        try secureStorage.store(object: data, account: accessCodeListKey, overwrite: true, context: context)
    }
}
