//
//  SecureEnclaveAlgorithm.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import Foundation

struct SecureEnclaveAlgorithm {
    // MARK: - Signing

    func sign(data: Data, privateKey: SecKey) throws -> Data {
        let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA512
        guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
            throw SecureEnclaveError.algorithmNotSupported
        }

        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(privateKey, algorithm, data as CFData,  &error) as Data? else {
            let underlyingError = error!.takeRetainedValue() as Error
            throw SecureEnclaveError.signingFailed(underlyingError: underlyingError)
        }

        return signature
    }

    func verify(signature: Data, message: Data, privateKey: SecKey) throws -> Bool {
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw SecureEnclaveError.publicKeyGenerationFailed
        }

        let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA512
        guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
            throw SecureEnclaveError.algorithmNotSupported
        }


        var error: Unmanaged<CFError>?
        guard SecKeyVerifySignature(publicKey, algorithm, message as CFData, signature as CFData, &error) else {
            let verificationError = error!.takeRetainedValue() as Error
            Log.error(verificationError)
            return false
        }

        return true
    }

    // MARK: - ECIES

    func encryptData(_ data: Data, privateKey: SecKey) throws -> Data {
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw SecureEnclaveError.publicKeyGenerationFailed
        }

        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
            throw SecureEnclaveError.algorithmNotSupported
        }

        var error: Unmanaged<CFError>?
        let encryptedData = SecKeyCreateEncryptedData(publicKey, algorithm, data as CFData, &error) as Data?

        guard let encryptedData else {
            let underlyingError = error!.takeRetainedValue() as Error
            throw SecureEnclaveError.encryptionFailed(underlyingError: underlyingError)
        }

        return encryptedData
    }

    /// SecKeyCreateDecryptedData call is blocking when the used key
    /// is protected by biometry authentication.
    func decryptData(_ data: Data, privateKey: SecKey) throws -> Data {
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw SecureEnclaveError.publicKeyGenerationFailed
        }

        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
            throw SecureEnclaveError.algorithmNotSupported
        }

        var error: Unmanaged<CFError>?
        let decryptedData = SecKeyCreateDecryptedData(privateKey, algorithm, data as CFData, &error) as Data?

        guard let decryptedData else {
            let underlyingError = error!.takeRetainedValue() as Error
            throw SecureEnclaveError.decryptionFailed(underlyingError: underlyingError)
        }

        return decryptedData
    }
}
