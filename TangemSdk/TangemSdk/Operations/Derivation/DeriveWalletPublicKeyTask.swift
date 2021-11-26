//
//  DeriveWalletPublicKeyTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 05.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
/// Derive wallet  public key according to BIP32 (Private parent key → public child key)
public class DeriveWalletPublicKeyTask: CardSessionRunnable {
    public var preflightReadMode: PreflightReadMode = .readCardOnly
    
    private let walletPublicKey: Data
    private let derivationPath: DerivationPath
    
    /// Default initializer
    /// - Parameters:
    ///   - walletPublicKey: Seed public key.
    ///   - derivationPath: Derivation path
    public init(walletPublicKey: Data, derivationPath: DerivationPath) {
        self.walletPublicKey = walletPublicKey
        self.derivationPath = derivationPath
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<ExtendedPublicKey>) {
        let readWallet = ReadWalletCommand(publicKey: walletPublicKey, derivationPath: derivationPath)
        readWallet.run(in: session) { result in
            switch result {
            case .success(let response):
                guard let chainCode = response.wallet.chainCode else {
                    completion(.failure(.cardError))
                    return
                }
                
                let childKey = ExtendedPublicKey(compressedPublicKey: response.wallet.publicKey,
                                                 chainCode: chainCode,
                                                 derivationPath: self.derivationPath)
                
                completion(.success(childKey))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
