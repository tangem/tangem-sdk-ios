//
//  AuthorizeWithSecurityDelayCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20/02/2026.
//

import Foundation

struct AuthorizeWithSecurityDelayResponse {
    let pubSessionKeyA: Data
    let signAttestA: Data

    func verify(with cardPublicKey: Data) throws -> Bool {
       return try CryptoUtils.verify(
            curve: .secp256k1,
            publicKey: cardPublicKey,
            message: Data("SESSION.CARD".utf8) + pubSessionKeyA,
            signature: signAttestA
        )
    }
}

/// First step of the security delay secure channel establishment.
/// Sends an authorize command with `.secureDelay` interaction mode.
/// Returns the card's session public key and attestation signature.
class AuthorizeWithSecurityDelayCommand: Command {
    typealias CommandResponse = AuthorizeWithSecurityDelayResponse

    var preflightReadMode: PreflightReadMode { .none }
    var usesEncryption: Bool { false }
    var accessLevel: AccessLevel { .publicAccess }

    func run(in session: CardSession, completion: @escaping CompletionResult<AuthorizeWithSecurityDelayResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let authorizeResponse):
                do {
                    guard let card = session.environment.card else {
                        throw TangemSdkError.missingPreflightRead
                    }

                    if try authorizeResponse.verify(with: card.cardPublicKey) {
                        completion(.success(authorizeResponse))
                    } else {
                        completion(.failure(.verificationFailed))
                    }
                } catch {
                    completion(.failure(error.toTangemSdkError()))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.interactionMode, value: AuthorizeMode.secureDelay)

        return CommandApdu(.authorize, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> AuthorizeWithSecurityDelayResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return AuthorizeWithSecurityDelayResponse(
            pubSessionKeyA: try decoder.decode(.sessionKeyA),
            signAttestA: try decoder.decode(.cardSignature)
        )
    }
}
