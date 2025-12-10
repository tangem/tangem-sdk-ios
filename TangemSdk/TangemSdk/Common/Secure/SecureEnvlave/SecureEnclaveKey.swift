//
//  SecureEnclaveKey.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import Foundation
import LocalAuthentication

struct SecureEnclaveKey {
    func makeKey(tag: String, flags: SecAccessControlCreateFlags) throws -> SecKey {
        let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            flags,
            nil)!

        let attributes: NSDictionary = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationTag: tag,
                kSecAttrAccessControl: accessControl,
            ]
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes, &error) else {
            throw error!.takeRetainedValue() as Error
        }

        return privateKey
    }

    func restoreKey(tag: String, context: LAContext?) -> SecKey? {
        var query: [String: Any] = [
            kSecClass as String                 : kSecClassKey,
            kSecAttrApplicationTag as String    : tag,
            kSecAttrKeyType as String           : kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String             : true,
        ]

        if let context {
            query[kSecUseAuthenticationContext as String] = context
        }

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            return nil
        }

        return (item as! SecKey)
    }

    func delete(tag: String) {
        let query: [String: Any] = [
            kSecClass as String                 : kSecClassKey,
            kSecAttrApplicationTag as String    : tag,
            kSecAttrKeyType as String           : kSecAttrKeyTypeECSECPrimeRandom,
        ]

        // status intentionally omitted because data could be absent
        _ = SecItemDelete(query as CFDictionary)
    }
}
