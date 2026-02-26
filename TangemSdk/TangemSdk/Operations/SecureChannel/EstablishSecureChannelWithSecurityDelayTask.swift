//
//  EstablishSecureChannelWithSecurityDelayTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 26/02/2026.
//

import Foundation

/// Orchestrates secure channel establishment using ECDH key exchange for v8+ cards.
/// Uses security delay-based authorization with card attestation verification.
class EstablishSecureChannelWithSecurityDelayTask: CardSessionRunnable {
    typealias Response = Void

    var preflightReadMode: PreflightReadMode { .none }

    func run(in session: CardSession, completion: @escaping CompletionResult<Void>) {
        Log.session("Establish encryption with security delay")

        session.environment.encryptionMode = .none
        session.environment.encryptionKey = nil
        session.environment.secureChannelSession?.reset()

        guard let cardPublicKey = session.environment.card?.cardPublicKey else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard let cardId = session.environment.card?.cardId else {
            completion(.failure(.missingPreflightRead))
            return
        }

        AuthorizeWithSecurityDelayCommand().run(in: session) { result in
            switch result {
            case .success(let authorizeResponse):
                do {
                    // Verify card attestation
                    let isValid = try CryptoUtils.verify(
                        curve: .secp256k1,
                        publicKey: cardPublicKey,
                        message: Data("SESSION.CARD".utf8) + authorizeResponse.pubSessionKeyA,
                        signature: authorizeResponse.signAttestA
                    )

                    guard isValid else {
                        throw TangemSdkError.cryptoUtilsError("Card attest signature is invalid!")
                    }

                    Log.session("Card attest signature - OK")

                    let encryptionHelper = try StrongEncryptionHelper()
                    self.completeEstablishment(
                        encryptionHelper: encryptionHelper,
                        pubSessionKeyA: authorizeResponse.pubSessionKeyA,
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
        encryptionHelper: StrongEncryptionHelper,
        pubSessionKeyA: Data,
        cardId: String,
        in session: CardSession,
        completion: @escaping CompletionResult<Void>
    ) {
        OpenSessionWithSecurityDelayCommand(sessionKeyB: encryptionHelper.keyA).run(in: session) { result in
            switch result {
            case .success(let openResponse):
                do {
                    let sessionKey = try encryptionHelper.generateSecret(keyB: pubSessionKeyA).getSHA256()
                    session.environment.encryptionMode = .ccmWithSecurityDelay
                    session.environment.encryptionKey = sessionKey
                    session.environment.secureChannelSession?.didEstablishChannel(accessLevel: openResponse.accessLevel, cardId: cardId)

                    Log.session("Secure channel established with security delay")
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
