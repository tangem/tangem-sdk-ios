//
//  EstablishSecureChannelWithAccessTokenTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 26/02/2026.
//

import Foundation

/// Orchestrates secure channel establishment using access tokens for v8+ cards.
/// Performs challenge-response with HMAC-based attestation, then derives a session key.
class EstablishSecureChannelWithAccessTokenTask: CardSessionRunnable {
    typealias Response = Void

    var preflightReadMode: PreflightReadMode { .none }
    var accessLevel: AccessLevel { .publicAccess }

    func run(in session: CardSession, completion: @escaping CompletionResult<Void>) {
        AuthorizeWithAccessTokensCommand().run(in: session) { result in
            switch result {
            case .success(let authorizeResponse):
                self.completeEstablishment(
                    authorizeResponse: authorizeResponse,
                    in: session,
                    completion: completion
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func completeEstablishment(authorizeResponse: AuthorizeWithAccessTokenResponse, in session: CardSession, completion: @escaping CompletionResult<Void>) {
        do {
            guard let accessTokens = session.environment.secureChannelSession?.cardAccessTokens else {
                throw TangemSdkError.missingAccessTokens
            }

            let challengeB = try CryptoUtils.generateRandomBytes(count: 32)
            let accessKey = try accessTokens.accessToken.xor(with: authorizeResponse.challengeA)
            let input = Data("SESSION.TERM".utf8) + authorizeResponse.challengeA + challengeB
            let hmacAttestB = accessKey.hmacSHA256(input: input)
            let salt = accessTokens.identifyToken + authorizeResponse.challengeA + challengeB

            OpenSessionWithAccessTokenCommand(
                challengeB: challengeB,
                hmacAttestB: hmacAttestB,
                accessKey: accessKey,
                salt: salt
            ).run(in: session) { result in
                switch result {
                case .success(let openResponse):
                    do {
                        guard let card = session.environment.card else {
                            throw TangemSdkError.missingPreflightRead
                        }

                        // Derive session key
                        let sessionKey = try accessKey.pbkdf2sha256(
                            salt: accessTokens.identifyToken + authorizeResponse.challengeA + challengeB,
                            rounds: 10
                        )

                        session.environment.encryptionMode = .ccmWithAccessToken
                        session.environment.encryptionKey = sessionKey
                        session.environment.secureChannelSession?.didEstablishChannel(accessLevel: openResponse.accessLevel, cardId: card.cardId)
                        completion(.success(()))
                    } catch {
                        completion(.failure(error.toTangemSdkError()))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error.toTangemSdkError()))
        }
    }
}
