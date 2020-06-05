//
//  SecureStorageService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Security

/// Helper class for Keychain
class SecureStorageService: NSObject {
    func get(key: String) -> Any? {
        let query: [String: Any] = [
            kSecClass as String      : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecMatchLimit as String  : kSecMatchLimitOne,
            kSecReturnData as String : true
        ]
        
        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        if status == noErr, let data = result as? Data {
            return NSKeyedUnarchiver.unarchiveObject(with: data)
        }
        
        return nil
    }
    
    @discardableResult
    func store(object: Any, key: String) -> Bool {
        let data = NSKeyedArchiver.archivedData(withRootObject: object)
        
        let query: [String : Any] = [
            kSecClass as String : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecValueData as String : data,
            kSecAttrAccessible  as String : kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}
