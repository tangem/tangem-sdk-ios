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

    func run(in session: CardSession, completion: @escaping CompletionResult<Void>) {
        Log.session("Establish encryption with access token")

        session.environment.encryptionMode = .none
        session.environment.encryptionKey = nil
        session.environment.secureChannelSession?.reset()

        guard let cardPublicKey = session.environment.card?.cardPublicKey else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard let cardTokens = session.environment.secureChannelSession?.cardTokens else {
            completion(.failure(.cryptoUtilsError("Missing card tokens")))
            return
        }

        guard let cardId = session.environment.card?.cardId else {
            completion(.failure(.missingPreflightRead))
            return
        }

        AuthorizeWithAccessTokensCommand().run(in: session) { result in
            switch result {
            case .success(let authorizeResponse):
                do {
                    try self.completeEstablishment(
                        authorizeResponse: authorizeResponse,
                        cardTokens: cardTokens,
                        cardPublicKey: cardPublicKey,
                        cardId: cardId,
                        in: session,
                        completion: completion
                    )
                } catch {
                    completion(.failure(error.toTangemSdkError()))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func completeEstablishment(
        authorizeResponse: AuthorizeWithAccessTokenResponse,
        cardTokens: CardTokens,
        cardPublicKey: Data,
        cardId: String,
        in session: CardSession,
        completion: @escaping CompletionResult<Void>
    ) throws {
        let challengeA = authorizeResponse.challengeA
        let hmacAttestA = authorizeResponse.hmacAttestA

        // Verify card attestation
        let identifyKey = try cardTokens.identifyToken.xor(with: challengeA)
        let hmacCalculated = identifyKey.hmacSHA256(input: Data("SESSION.CARD".utf8) + challengeA)
        guard hmacCalculated == hmacAttestA else {
            Log.error("Card attest HMAC (hmacAttestA) is invalid!")
            throw TangemSdkError.cryptoUtilsError("Invalid access tokens")
        }

        // Prepare terminal attestation
        let challengeB = try CryptoUtils.generateRandomBytes(count: 32)
        let accessKey = try cardTokens.accessToken.xor(with: challengeA)
        let hmacAttestB = accessKey.hmacSHA256(input: Data("SESSION.TERM".utf8) + challengeA + challengeB)

        OpenSessionWithAccessTokenCommand(challengeB: challengeB, hmacAttestB: hmacAttestB).run(in: session) { result in
            switch result {
            case .success(let openResponse):
                do {
                    // Derive session key
                    let sessionKey = try accessKey.pbkdf2sha256(
                        salt: cardTokens.identifyToken + challengeA + challengeB,
                        rounds: 10
                    )

                    // Verify session attestation
                    let isValid = try CryptoUtils.verify(
                        curve: .secp256k1,
                        publicKey: cardPublicKey,
                        message: Data("SESSION.KEY".utf8) + sessionKey,
                        signature: openResponse.signAttestSession
                    )

                    guard isValid else {
                        throw TangemSdkError.cryptoUtilsError("Session attest signature (signAttestSession) is invalid!")
                    }

                    session.environment.encryptionMode = .ccmWithAccessToken
                    session.environment.encryptionKey = sessionKey
                    session.environment.secureChannelSession?.didEstablishChannel(accessLevel: openResponse.accessLevel, cardId: cardId)

                    Log.session("Secure channel established with access token")
                    completion(.success(()))
                } catch {
                    completion(.failure(error.toTangemSdkError()))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
