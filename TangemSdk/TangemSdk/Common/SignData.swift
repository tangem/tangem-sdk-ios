//
//  SignData.swift
//  TangemSdk
//
//  Created by Dmitry Fedorov on 24.07.2025.
//

import Foundation

public struct SignData {
    public let derivationPath: DerivationPath?
    public let hashes: [Data]
    public let publicKey: Data
    
    public init(derivationPath: DerivationPath?, hashes: [Data], publicKey: Data) {
        self.derivationPath = derivationPath
        self.hashes = hashes
        self.publicKey = publicKey
    }
}
