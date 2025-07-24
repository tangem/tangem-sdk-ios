//
//  SignData.swift
//  TangemSdk
//
//  Created by Dmitry Fedorov on 24.07.2025.
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
