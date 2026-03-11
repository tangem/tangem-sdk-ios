//
//  ManageAccessTokensTask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

/// Get or renew access tokens
class ManageAccessTokensTask: CardSessionRunnable {
    typealias Response = Void

    deinit {
        Log.debug("ManageAccessTokensTask deinit")
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<Void>) {
        ManageAccessTokensCommand(mode: .get).run(in: session) { result in
            switch result {
            case .success(let response):
                if response.isZeroResponse {
                    let command = ManageAccessTokensCommand(mode: .renew)
                    command.run(in: session) { result in
                        switch result {
                        case .success:
                            completion(.success(()))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                        withExtendedLifetime(command) {}
                    }
                } else {
                    completion(.success(()))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

