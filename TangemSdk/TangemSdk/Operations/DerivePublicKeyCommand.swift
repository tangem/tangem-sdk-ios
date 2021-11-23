//
//  DerivePublicKeyCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 05.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
/// Derive public key according to BIP32 (Private parent key → public child key)
public class DerivePublicKeyCommand: CardSessionRunnable {
    public var preflightReadMode: PreflightReadMode = .readCardOnly
    
    private let walletPublicKey: Data
    private let hdPath: DerivationPath
    
    /// Default initializer
    /// - Parameters:
    ///   - walletPublicKey: Public key of wallet that should derive the key.
    ///   - hdPath: Derivation path
    public init(walletPublicKey: Data, hdPath: DerivationPath) {
        self.walletPublicKey = walletPublicKey
        self.hdPath = hdPath
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<ExtendedPublicKey>) {
        let readWallet = ReadWalletCommand(publicKey: walletPublicKey, hdPath: hdPath)
        readWallet.run(in: session) { result in
            switch result {
            case .success(let response):
                guard let chainCode = response.wallet.chainCode else {
                    completion(.failure(.cardError))
                    return
                }
                
                let childKey = ExtendedPublicKey(compressedPublicKey: response.wallet.publicKey,
                                                 chainCode: chainCode)
                
                completion(.success(childKey))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
