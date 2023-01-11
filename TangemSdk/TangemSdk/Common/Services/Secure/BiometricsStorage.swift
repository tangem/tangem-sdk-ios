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
    private let context = LAContext.default
  
    public init() {}
    
    public func get(_ account: String, context: LAContext? = nil) throws -> Data? {
        Log.debug("BiometricsStorage \(account) get - fetching key")
        
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
        Log.debug("BiometricsStorage \(account) get - status \(status.message) \(status)")
        switch  status {
        case errSecSuccess:
            guard let data = result as? Data else {
                Log.debug("BiometricsStorage \(account) get - data nil")
                return nil
            }
            
            Log.debug("BiometricsStorage \(account) get - data not nil")
            return data
        case errSecItemNotFound:
            Log.debug("BiometricsStorage \(account) get - not found")
            return nil
        case errSecUserCanceled:
            Log.debug("BiometricsStorage \(account) get - user cancelled")
            throw TangemSdkError.userCancelled
        case let status:
            Log.debug("BiometricsStorage \(account) get - error \(status.message)")
            let error = KeyStoreError("Keychain read failed: \(status.message)")
            throw error
        }
    }
    
    public func store(_ object: Data, forKey account: String, overwrite: Bool = true, context: LAContext? = nil) throws {
        Log.debug("BiometricsStorage \(account) set - setting data")
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecUseDataProtectionKeychain: true,
            kSecValueData: object,
            kSecAttrAccessControl: self.makeBiometricAccessControl(),
            kSecUseAuthenticationContext: context ?? self.context,
        ]
        
        var status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem && overwrite {
            var searchQuery: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: account,
                kSecUseDataProtectionKeychain: true,
                kSecAttrAccessControl: self.makeBiometricAccessControl(),
                kSecUseAuthenticationContext: context ?? self.context
            ]
            
            Log.debug("BiometricsStorage \(account) set - failed to set a duplicate, overwriting")
            let attributes = [kSecValueData: object] as [String: Any]
            status = SecItemUpdate(searchQuery as CFDictionary, attributes as CFDictionary)
        }
        
        Log.debug("BiometricsStorage \(account) set - status \(status.message) \(status)")
        
        switch status {
        case errSecSuccess:
            Log.debug("BiometricsStorage \(account) set - OK")
            break
        case errSecUserCanceled:
            Log.debug("BiometricsStorage \(account) set - user cancelled")
            throw TangemSdkError.userCancelled
        default:
            Log.debug("BiometricsStorage \(account) set - error \(status.message)")
            let error = KeyStoreError("Unable to store item: \(status.message)")
            throw error
        }
    }
    
    public func delete(_ account : String) throws {
        Log.debug("BiometricsStorage \(account) delete")
        
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecUseDataProtectionKeychain: true,
            kSecAttrAccount: account,
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        Log.debug("BiometricsStorage \(account) delete - status \(status.message) \(status)")
        
        switch status {
        case errSecItemNotFound, errSecSuccess:
            break
        case let status:
            let error = KeyStoreError("Unexpected deletion error: \(status.message)")
            throw error.toTangemSdkError()
        }
    }
    
    func get(_ storageKey: SecureStorageKey, context: LAContext? = nil) throws -> Data? {
        try get(storageKey.rawValue, context: context)
    }
    
    func store(_ object: Data, forKey storageKey: SecureStorageKey, overwrite: Bool = true, context: LAContext? = nil) throws {
         try store(object, forKey: storageKey.rawValue, overwrite: overwrite, context: context)
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
