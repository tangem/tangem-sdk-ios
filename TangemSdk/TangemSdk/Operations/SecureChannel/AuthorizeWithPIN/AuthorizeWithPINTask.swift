//
//  AuthorizeWithPINTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 26/02/2026.
//

import Foundation

/// Orchestrates PIN challenge-response authorization for v8+ cards.
/// Sends a challenge request, then responds with HMAC of the access code.
class AuthorizeWithPINTask: CardSessionRunnable {
    typealias Response = Void

    var preflightReadMode: PreflightReadMode { .none }

    deinit {
        Log.debug("AuthorizeWithPINTask deinit")
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<Void>) {
        Log.session("authorizeWithPin")

        AuthorizeWithPinChallengeCommand().run(in: session) { challengeResult in
            switch challengeResult {
            case .success(let challengeResponse):
                AuthorizeWithPinResponseCommand(challengeWithXor: challengeResponse.challengeWithXor).run(in: session) { responseResult in
                    switch responseResult {
                    case .success(let pinResponse):
                        session.secureChannelSession?.didAuthorizePin(accessLevel: pinResponse.accessLevel)
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
