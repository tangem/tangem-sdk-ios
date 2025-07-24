//
//  SignData.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public struct SignData {
    public let derivationPath: DerivationPath?
    public let hash: Data
    public let publicKey: Data
    
    public init(derivationPath: DerivationPath?, hash: Data, publicKey: Data) {
        self.derivationPath = derivationPath
        self.hash = hash
        self.publicKey = publicKey
    }
}
