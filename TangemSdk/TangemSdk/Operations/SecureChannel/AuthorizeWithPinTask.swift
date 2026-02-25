//
//  AuthorizeWithPinTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20/02/2026.
//

import Foundation

/// Orchestrates PIN challenge-response authorization for v8+ cards.
/// Sends a challenge request, then responds with HMAC of the access code.
class AuthorizeWithPinTask: CardSessionRunnable {
    typealias Response = Bool

    func run(in session: CardSession, completion: @escaping CompletionResult<Bool>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard card.firmwareVersion >= .v8 else {
            completion(.success(true))
            return
        }

        authorizeWithPin(in: session, completion: completion)
    }

    private func authorizeWithPin(in session: CardSession, completion: @escaping CompletionResult<Bool>) {
        Log.session("authorizeWithPin")

        AuthorizeWithPinChallengeCommand().run(in: session) { [weak self] result in
            switch result {
            case .success(let challengeResponse):
                AuthorizeWithPinResponseCommand(challenge: challengeResponse.challenge).run(in: session) { responseResult in
                    switch responseResult {
                    case .success(let pinResponse):
                        session.environment.secureChannelSession?.didAuthorizePin(accessLevel: pinResponse.accessLevel)
                        completion(.success(true))
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
