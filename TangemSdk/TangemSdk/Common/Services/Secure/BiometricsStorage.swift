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
public class BiometricsStorage {
    private let context: LAContext = .default
  
    public init() {}
    
    public func get(_ account: String, context: LAContext? = nil) -> Result<Data?, TangemSdkError> {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecUseDataProtectionKeychain: true,
            kSecReturnData: true,
            kSecUseAuthenticationContext: context ?? self.context,
        ]
        
        var result: AnyObject?
        
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch  status {
        case errSecSuccess:
            guard let data = result as? Data else {
                return .success(nil)
            }
            
            return .success(data)
        case errSecItemNotFound:
            return .success(nil)
        case errSecUserCanceled:
            return .failure(.userCancelled)
        case let status:
            let error = KeyStoreError("Keychain read failed: \(status.message)")
            return .failure(error.toTangemSdkError())
        }
    }
    
    public func store(_ object: Data, forKey account: String, overwrite: Bool = true, context: LAContext? = nil) -> Result<Void, TangemSdkError> {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecUseDataProtectionKeychain: true,
            kSecValueData: object,
            kSecAttrAccessControl: self.makeBiometricAccessControl(),
        ]
        
        if let context = context {
            query[kSecUseAuthenticationContext] = context
        }
        
        var status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem && overwrite {
            var searchQuery: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: account,
                kSecUseDataProtectionKeychain: true,
                kSecAttrAccessControl: self.makeBiometricAccessControl(),
            ]
        
            if let context = context {
                searchQuery[kSecUseAuthenticationContext] = context
            }
            
            let attributes = [kSecValueData: object] as [String: Any]
            status = SecItemUpdate(searchQuery as CFDictionary, attributes as CFDictionary)
        }
        
        switch status {
        case errSecSuccess:
            return .success(())
        case errSecUserCanceled:
            return .failure(.userCancelled)
        default:
            let error = KeyStoreError("Unable to store item: \(status.message)")
            return .failure(error.toTangemSdkError())
        }
    }
    
    public func delete(_ account : String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecUseDataProtectionKeychain: true,
            kSecAttrAccount: account,
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecItemNotFound, errSecSuccess:
            break
        case let status:
            let error = KeyStoreError("Unexpected deletion error: \(status.message)")
            throw error.toTangemSdkError()
        }
    }
    
    func get(_ storageKey: SecureStorageKey) -> Result<Data?, TangemSdkError> {
        get(storageKey.rawValue)
    }
    
    func store(_ object: Data, forKey storageKey: SecureStorageKey, overwrite: Bool = true) -> Result<Void, TangemSdkError> {
         store(object, forKey: storageKey.rawValue)
    }
    
    func delete(_ storageKey: SecureStorageKey) throws {
        try delete(storageKey.rawValue)
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
