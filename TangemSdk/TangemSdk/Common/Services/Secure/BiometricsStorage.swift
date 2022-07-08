//
//  BiometricsStorage.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 06.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Security
import LocalAuthentication

/// Helper class for Keychain
@available(iOS 13.0, *)
struct BiometricsStorage {
    func get(account: SecureStorageKey, completion: @escaping (Result<Data?, TangemSdkError>) -> Void) {
        DispatchQueue.global().async {
            let query = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: account.rawValue,
                kSecMatchLimit: kSecMatchLimitOne,
                kSecUseDataProtectionKeychain: true,
                kSecReturnData: true,
            ] as [String: Any]
            
            var result: AnyObject?
            
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            switch  status {
            case errSecSuccess:
                guard let data = result as? Data else {
                    completion(.success(nil))
                    return
                }
                
                completion(.success(data))
            case errSecItemNotFound:
                completion(.success(nil))
            case errSecUserCanceled:
                completion(.failure(.userCancelled))
            case let status:
                let error = KeyStoreError("Keychain read failed: \(status.message)")
                completion(.failure(error.toTangemSdkError()))
            }
        }
    }
    
    func store(object: Data, account: SecureStorageKey, overwrite: Bool = true, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        DispatchQueue.global().async {
            let query = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: account.rawValue,
                kSecUseDataProtectionKeychain: true,
                kSecValueData: object,
                kSecAttrAccessControl: makeBiometricAccessControl()
            ] as [String: Any]
            
            var status = SecItemAdd(query as CFDictionary, nil)
            
            if status == errSecDuplicateItem && overwrite {
                let searchQuery = [
                    kSecClass: kSecClassGenericPassword,
                    kSecAttrAccount: account.rawValue,
                    kSecUseDataProtectionKeychain: true,
                    kSecAttrAccessControl: makeBiometricAccessControl(),
                ] as [CFString: Any]
                
                let attributes = [kSecValueData: object] as [String: Any]
                status = SecItemUpdate(searchQuery as CFDictionary, attributes as CFDictionary)
            }
            
            switch status {
            case errSecSuccess:
                completion(.success(()))
            case errSecUserCanceled:
                completion(.failure(.userCancelled))
            default:
                let error = KeyStoreError("Unable to store item: \(status.message)")
                completion(.failure(error.toTangemSdkError()))
            }
        }
    }
    
    /// Removes any existing data with the given account.
    func delete(account: SecureStorageKey) throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecUseDataProtectionKeychain: true,
            kSecAttrAccount: account.rawValue,
        ] as [String: Any]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecItemNotFound, errSecSuccess:
            break
        case let status:
            let error = KeyStoreError("Unexpected deletion error: \(status.message)")
            throw error.toTangemSdkError()
        }
    }
    
    private func makeBiometricAccessControl() -> SecAccessControl {
        return SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .biometryCurrentSet,
            nil
        )!
    }
}
