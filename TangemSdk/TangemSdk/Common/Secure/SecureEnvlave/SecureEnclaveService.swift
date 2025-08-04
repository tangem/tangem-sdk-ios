//
//  SecureEnclaveService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 25.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication

public struct SecureEnclaveService {
    private let util = SecureEnclaveAlgorithm()
    private let keyUtil = SecureEnclaveKey()

    public init() {}

    private func makeOrRestoreKey(tag: String) throws -> SecKey {
        if let restoredKey = keyUtil.restoreKey(tag: tag, context: nil) {
            return restoredKey
        }

        return try keyUtil.makeKey(tag: tag, flags: [.privateKeyUsage])
    }
}

// MARK: - Signing

public extension SecureEnclaveService {
    func sign(data: Data, keyTag: String) throws -> Data {
        let privateKey = try makeOrRestoreKey(tag: keyTag)
        return try util.sign(data: data, privateKey: privateKey)
    }

    func verify(signature: Data, message: Data, keyTag: String) throws -> Bool {
        let privateKey = try makeOrRestoreKey(tag: keyTag)
        return try util.verify(signature: signature, message: message, privateKey: privateKey)
    }
}

// MARK: - ECIES

public extension SecureEnclaveService {
    func encryptData(_ data: Data, keyTag: String) throws -> Data {
        let privateKey = try makeOrRestoreKey(tag: keyTag)
        return try util.encryptData(data, privateKey: privateKey)
    }

    func decryptData(_ data: Data, keyTag: String) throws -> Data {
        let privateKey = try makeOrRestoreKey(tag: keyTag)
        return try util.decryptData(data, privateKey: privateKey)
    }
}

// MARK: - SecureStorageKey

extension SecureEnclaveService {
    func sign(data: Data, storageKey: SecureStorageKey) throws -> Data {
        try sign(data: data, keyTag: storageKey.rawValue)
    }

    func verify(signature: Data, message: Data, storageKey: SecureStorageKey) throws -> Bool {
        try verify(signature: signature, message: message, keyTag: storageKey.rawValue)
    }

    func encryptData(_ data: Data, storageKey: SecureStorageKey) throws -> Data {
        try encryptData(data, keyTag: storageKey.rawValue)
    }

    func decryptData(_ data: Data, storageKey: SecureStorageKey) throws -> Data {
        try decryptData(data, keyTag: storageKey.rawValue)
    }
}
