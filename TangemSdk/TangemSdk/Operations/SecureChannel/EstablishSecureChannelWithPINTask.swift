//
//  EstablishSecureChannelWithPINTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 26/02/2026.
//

import Foundation

/// Orchestrates PIN challenge-response authorization for v8+ cards.
/// Sends a challenge request, then responds with HMAC of the access code.
class EstablishSecureChannelWithPINTask: CardSessionRunnable {
    typealias Response = Void

    var preflightReadMode: PreflightReadMode { .none }

    func run(in session: CardSession, completion: @escaping CompletionResult<Void>) {
        Log.session("authorizeWithPin")

        AuthorizeWithPinChallengeCommand().run(in: session) { result in
            switch result {
            case .success(let challengeResponse):
                AuthorizeWithPinResponseCommand(challenge: challengeResponse.challenge).run(in: session) { responseResult in
                    switch responseResult {
                    case .success(let pinResponse):
                        session.environment.secureChannelSession?.didAuthorizePin(accessLevel: pinResponse.accessLevel)
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
