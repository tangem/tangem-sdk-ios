//
//  OnlineAttestationVerifier.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24/03/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct OnlineAttestationVerifier {
    private let cardPublicKey: Data
    private let issuerPublicKey: Data
    private let newAttestationService: Bool

    init(cardPublicKey: Data, issuerPublicKey: Data, newAttestationService: Bool) {
        self.cardPublicKey = cardPublicKey
        self.issuerPublicKey = issuerPublicKey
        self.newAttestationService = newAttestationService
    }

    func verify(response: OnlineAttestationResponse) throws -> Bool {
        // TODO: REMOVE WITH newAttestationService TOGGLE
        if newAttestationService {
            guard let manufacturerSignature = response.manufacturerSignature else {
                return false
            }

            return try verifyManufacturerSignature(signature: manufacturerSignature)
            && verifyIssuerSignature(signature: response.issuerSignature)
        } else {
            return try verifyIssuerSignature(signature: response.issuerSignature)
        }
    }

    private func verifyManufacturerSignature(signature: Data) throws -> Bool {
        let compressedIssuerPublicKey = try Secp256k1Key(with: issuerPublicKey).compress()
        let manufacturerPublicKeys = ManufacturerKey.allCases

        for manufacturerPublicKey in manufacturerPublicKeys {
            let isValid = try CryptoUtils.verify(
                curve: .secp256k1,
                publicKey: manufacturerPublicKey.keyData,
                message: compressedIssuerPublicKey,
                signature: signature
            )

            Log.debug("Manufacturer signature is valid: \(isValid) for key: \(manufacturerPublicKey.manufacturerName)")

            if isValid {
                return true
            }
        }

        return false
    }

    private func verifyIssuerSignature(signature: Data) throws -> Bool {
        let isValid = try CryptoUtils.verify(
            curve: .secp256k1,
            publicKey: issuerPublicKey,
            message: cardPublicKey,
            signature: signature
        )

        Log.debug("Issuer signature is valid: \(isValid)")
        return isValid
    }
}
