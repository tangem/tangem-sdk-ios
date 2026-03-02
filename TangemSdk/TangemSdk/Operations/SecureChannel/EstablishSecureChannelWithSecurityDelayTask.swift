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
    var accessLevel: AccessLevel { .publicAccess }

    func run(in session: CardSession, completion: @escaping CompletionResult<Void>) {
        AuthorizeWithSecurityDelayCommand().run(in: session) { result in
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

    private func completeEstablishment(
        authorizeResponse: AuthorizeWithSecurityDelayResponse,
        in session: CardSession,
        completion: @escaping CompletionResult<Void>
    ) {
        do {
            let encryptionHelper = try StrongEncryptionHelper()
            let sessionKeyB = encryptionHelper.keyA

            OpenSessionWithSecurityDelayCommand(sessionKeyB: sessionKeyB).run(in: session) { result in
                switch result {
                case .success(let openResponse):
                    do {
                        let sessionKey = try encryptionHelper.generateSecret(keyB: authorizeResponse.pubSessionKeyA).getSHA256()
                        session.environment.encryptionMode = .ccmWithSecurityDelay
                        session.environment.encryptionKey = sessionKey
                        session.secureChannelSession?.didEstablishChannel(accessLevel: openResponse.accessLevel)

                        Log.session("Secure channel established with security delay")
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
