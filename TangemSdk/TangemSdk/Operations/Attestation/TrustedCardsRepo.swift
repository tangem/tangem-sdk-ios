//
//  TrustedCardsRepo.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 16.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public class TrustedCardsRepo {
    private let storage = Storage()
    private let secureStorage = SecureStorage()
    private let secureEnclave = SecureEnclaveService()

    //Key is Hash of card's public key
    private var data: [Data: Attestation] = [:]
    
    init() {
        if storage.bool(forKey: .refreshedTrustedCardsRepo) {
            try? fetch()
        } else {
            try? clean()
            storage.set(boolValue: true, forKey: .refreshedTrustedCardsRepo)
        }
    }
    
    func append(cardPublicKey: Data, attestation: Attestation) {
        let maxIndex = data.map({ $0.value.index }).max() ?? 0
        var newAttestation = attestation
        newAttestation.index = maxIndex + 1
        
        if newAttestation.index >= Constants.maxCards,
           let keyWithMinIndex = data.min(by: { $0.value.index < $1.value.index })?.key {
            data[keyWithMinIndex] = nil
        }
        
        let hash = cardPublicKey.getSha256()
        data[hash] = newAttestation
        do {
            try save()
        } catch {
            Log.error(error)
        }
    }
    
    func attestation(for cardPublicKey: Data) -> Attestation? {
        let hash = cardPublicKey.getSha256()
        return data[hash]
    }
    
    private func save() throws {
        let convertedData = data.mapValues { $0.rawRepresentation }
        let encodedData = try JSONEncoder.tangemSdkEncoder.encode(convertedData)
        let encryptedData = try secureEnclave.encryptData(encodedData, storageKey: .attestedCardsEncryptionKey)
        try secureStorage.store(encryptedData, forKey: .attestedCards)
    }
    
    private func fetch() throws {
        if let encryptedData = try secureStorage.get(.attestedCards) {
            let encodedData = try secureEnclave.decryptData(encryptedData, storageKey: .attestedCardsEncryptionKey)
            let convertedData = try JSONDecoder.tangemSdkDecoder.decode([Data: String].self, from: encodedData)
            let data = convertedData.compactMapValues { Attestation(rawRepresentation: $0) }
            self.data = data
        }
    }
    
    private func clean() throws {
        try secureStorage.delete(.attestedCards)
    }
}

private extension TrustedCardsRepo {
    enum Constants {
        static var maxCards = 1000 //todo: Think about it!
    }
}
