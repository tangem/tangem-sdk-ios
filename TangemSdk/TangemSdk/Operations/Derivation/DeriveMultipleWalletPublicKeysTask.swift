//
//  DeriveMultipleWalletPublicKeysTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 17.12.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public class DeriveMultipleWalletPublicKeysTask: CardSessionRunnable {
    public typealias Response = [WalletIndex: [ExtendedPublicKey]]
    
    private let derivations: [WalletIndex: [DerivationPath]]
    private var response: Response = .init()
    
    public init(_ derivations: [WalletIndex: [DerivationPath]]) {
        self.derivations = derivations
    }
    
    deinit {
        Log.debug("DeriveMultipleWalletPublicKeysTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<Response>) {
        self.derive(keys: [WalletIndex](derivations.keys), index: 0, in: session, completion: completion)
    }
    
    private func derive(keys: [WalletIndex], index: Int, in session: CardSession, completion: @escaping CompletionResult<Response>) {
        if index == keys.count {
            completion(.success(response))
            return
        }
        
        let key = keys[index]
        let paths = derivations[key]!
        let task = DeriveWalletPublicKeysTask(walletIndex: key, derivationPaths: paths)
        task.run(in: session) { result in
            switch result {
            case .success(let derivedKeys):
                self.response[key] = derivedKeys
                self.derive(keys: keys, index: index + 1, in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
