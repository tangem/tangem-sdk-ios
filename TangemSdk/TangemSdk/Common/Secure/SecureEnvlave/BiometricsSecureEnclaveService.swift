//
//  BiometricsSecureEnclaveService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 04/08/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication

public struct BiometricsSecureEnclaveService {
    private let util = SecureEnclaveAlgorithm()
    private let keyUtil = SecureEnclaveKey()

    public init() {}

    private func makeOrRestoreKey(tag: String, context: LAContext) throws -> SecKey {
        if let restoredKey = keyUtil.restoreKey(tag: tag, context: context) {
            return restoredKey
        }

        return try keyUtil.makeKey(tag: tag, flags: [.privateKeyUsage, .biometryCurrentSet])
    }
}

// MARK: - Signing

public extension BiometricsSecureEnclaveService {
    func sign(data: Data, keyTag: String, context: LAContext) throws -> Data {
        let privateKey = try makeOrRestoreKey(tag: keyTag, context: context)
        return try util.sign(data: data, privateKey: privateKey)
    }

    func verify(signature: Data, message: Data, keyTag: String, context: LAContext) throws -> Bool {
        let privateKey = try makeOrRestoreKey(tag: keyTag, context: context)
        return try util.verify(signature: signature, message: message, privateKey: privateKey)
    }
}

// MARK: - ECIES

public extension BiometricsSecureEnclaveService {
    func encryptData(_ data: Data, keyTag: String, context: LAContext) throws -> Data {
        let privateKey = try makeOrRestoreKey(tag: keyTag, context: context)
        return try util.encryptData(data, privateKey: privateKey)
    }

    /// SecKeyCreateDecryptedData call is blocking when the used key
    /// is protected by biometry authentication.
    func decryptData(_ data: Data, keyTag: String, context: LAContext) throws -> Data {
        let privateKey = try makeOrRestoreKey(tag: keyTag, context: context)
        return try util.decryptData(data, privateKey: privateKey)
    }
}

// MARK: - SecureStorageKey

extension BiometricsSecureEnclaveService {
    func sign(data: Data, storageKey: SecureStorageKey, context: LAContext) throws -> Data {
        try sign(data: data, keyTag: storageKey.rawValue, context: context)
    }

    func verify(signature: Data, message: Data, storageKey: SecureStorageKey, context: LAContext) throws -> Bool {
        try verify(signature: signature, message: message, keyTag: storageKey.rawValue, context: context)
    }

    func encryptData(_ data: Data, storageKey: SecureStorageKey, context: LAContext) throws -> Data {
        try encryptData(data, keyTag: storageKey.rawValue, context: context)
    }

    func decryptData(_ data: Data, storageKey: SecureStorageKey, context: LAContext) throws -> Data {
        try decryptData(data, keyTag: storageKey.rawValue, context: context)
    }
}
