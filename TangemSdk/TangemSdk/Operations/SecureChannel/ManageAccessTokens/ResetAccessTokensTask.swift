//
//  ResetAccessTokensTask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

/// Reset access tokens on the card
public class ResetAccessTokensTask: CardSessionRunnable {
    public var preflightReadMode: PreflightReadMode { .readCardOnly }

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
