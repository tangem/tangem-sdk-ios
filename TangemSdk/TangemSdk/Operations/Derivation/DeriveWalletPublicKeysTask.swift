//
//  DeriveWalletPublicKeysTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.11.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation


@available(iOS 13.0, *)
/// Derive wallet public keys according to BIP32 (Private parent key → public child key)
public class DeriveWalletPublicKeysTask: CardSessionRunnable {
    public var preflightReadMode: PreflightReadMode = .readCardOnly
    
    private let walletPublicKey: Data
    private let derivationPathes: [DerivationPath]
    
    /// Default initializer
    /// - Parameters:
    ///   - walletPublicKey: Seed public key.
    ///   - derivationPathes: Multiple derivation pathes
    public init(walletPublicKey: Data, derivationPathes: [DerivationPath]) {
        self.walletPublicKey = walletPublicKey
        self.derivationPathes = derivationPathes
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<[ExtendedPublicKey]>) {
        runDerivation(at: 0, keys: [], in: session, completion: completion)
    }
    
    private func runDerivation(at index: Int, keys: [ExtendedPublicKey], in session: CardSession, completion: @escaping CompletionResult<[ExtendedPublicKey]>) {
  
        guard index < derivationPathes.count else {
            completion(.success(keys))
            return
        }
        
        let task = DeriveWalletPublicKeyTask(walletPublicKey: walletPublicKey, derivationPath: derivationPathes[index])
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
