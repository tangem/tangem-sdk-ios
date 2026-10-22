//
//  CardArtworksVerifier.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CardArtworksVerifier {
    func verify(
        imageData: Data,
        imagePrefix: Data,
        signature: Data
    ) throws -> Bool {
        let manufacturerPublicKeys = ManufacturerKey.allCases

        let message = imagePrefix + imageData

        for manufacturerPublicKey in manufacturerPublicKeys {
            let isValid = try CryptoUtils.verify(
                curve: .secp256k1,
                publicKey: manufacturerPublicKey.keyData,
                message: message,
                signature: signature
            )

            Log.debug("Manufacturer signature is valid: \(isValid) for key: \(manufacturerPublicKey.manufacturerName)")

            if isValid {
                return true
            }
        }

        return false
    }
}
