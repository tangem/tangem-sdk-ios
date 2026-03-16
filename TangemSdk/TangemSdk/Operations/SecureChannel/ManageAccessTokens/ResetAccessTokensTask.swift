//
//  ResetAccessTokensTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 16/03/2026.
//

import Foundation

/// Reset access tokens on the card
public class ResetAccessTokensTask: CardSessionRunnable {
    deinit {
        Log.debug("ResetAccessTokensTask deinit")
    }

    public init() {}

    public func run(in session: CardSession, completion: @escaping CompletionResult<Void>) {
        ManageAccessTokensCommand(mode: .reset)
            .run(in: session) { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
