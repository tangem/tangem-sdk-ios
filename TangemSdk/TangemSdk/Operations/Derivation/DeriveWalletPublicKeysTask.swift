//
//  DeriveWalletPublicKeysTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.11.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public class DeriveWalletPublicKeysTask: CardSessionRunnable {
    private let walletPublicKey: Data
    private let derivationPaths: [DerivationPath]
    
    /// Derive multiple wallet  public keys according to BIP32 (Private parent key → public child key).
    /// Warning: Only `secp256k1` and `ed25519` (BIP32-Ed25519 scheme) curves supported
    /// - Parameters:
    ///   - walletPublicKey: Seed public key.
    ///   - derivationPaths: Multiple derivation pathes
    public init(walletPublicKey: Data, derivationPaths: [DerivationPath]) {
        self.walletPublicKey = walletPublicKey
        self.derivationPaths = derivationPaths
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<[ExtendedPublicKey]>) {
        runDerivation(at: 0, keys: [], in: session, completion: completion)
    }
    
    private func runDerivation(at index: Int, keys: [ExtendedPublicKey], in session: CardSession, completion: @escaping CompletionResult<[ExtendedPublicKey]>) {
        guard index < derivationPaths.count else {
            completion(.success(keys))
            return
        }
        
        let task = DeriveWalletPublicKeyTask(walletPublicKey: walletPublicKey, derivationPath: derivationPaths[index])
        task.run(in: session) { result in
            switch result {
            case .success(let key):
                self.runDerivation(at: index + 1, keys: keys + [key], in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
