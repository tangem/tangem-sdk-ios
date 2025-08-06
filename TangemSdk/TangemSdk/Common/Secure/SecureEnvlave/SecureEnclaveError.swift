//
//  SecureEnclaveError.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 04/08/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public enum SecureEnclaveError: Error {
    case publicKeyGenerationFailed
    case algorithmNotSupported
    case signingFailed(underlyingError: Error)
    case verificationFailed(underlyingError: Error)
    case encryptionFailed(underlyingError: Error)
    case decryptionFailed(underlyingError: Error)
}
