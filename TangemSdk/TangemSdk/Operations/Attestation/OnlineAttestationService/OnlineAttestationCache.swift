//
//  OnlineAttestationCache.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication

public class OnlineAttestationCache {
    private let storage = Storage()
    private let secureStorage = SecureStorage()
    private let secureEnclave = SecureEnclaveService()

    //Key is Hash of card's public key
    private var data: [Data: OnlineAttestationResponse] = [:]

    init() {
        if storage.bool(forKey: .refreshedOnlineAttestationCache) {
            try? fetch()
        } else {
            try? clean()
            storage.set(boolValue: true, forKey: .refreshedOnlineAttestationCache)
        }
    }

    func append(cardPublicKey: Data, response: OnlineAttestationResponse) {
        let hash = cardPublicKey.getSHA256()
        data[hash] = response
        do {
            try save()
        } catch {
            Log.error(error)
        }
    }

    func response(for cardPublicKey: Data) -> OnlineAttestationResponse? {
        let hash = cardPublicKey.getSHA256()
        return data[hash]
    }

    private func save() throws {
        let encodedData = try JSONEncoder.tangemSdkEncoder.encode(data)
        let encryptedData = try secureEnclave.encryptData(encodedData, storageKey: .onlineAttestationResponsesEncryptionKey)
        try secureStorage.store(encryptedData, forKey: .onlineAttestationResponses)
    }

    private func fetch() throws {
        if let encryptedData = try secureStorage.get(.onlineAttestationResponses) {
           let encodedData = try secureEnclave.decryptData(encryptedData, storageKey: .onlineAttestationResponsesEncryptionKey)
            self.data = try JSONDecoder.tangemSdkDecoder.decode([Data: OnlineAttestationResponse].self, from: encodedData)
        }
    }

    private func clean() throws {
        try secureStorage.delete(.onlineAttestationResponses)
    }
}
