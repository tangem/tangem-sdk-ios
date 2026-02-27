//
//  AuthorizeWithPinResponseCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24/02/2026.
//

import Foundation

// MARK: - Response

struct AuthorizeWithPinResponseResponse {
    let accessLevel: AccessLevel
}

/// Sends the HMAC-based PIN response to the card for verification.
class AuthorizeWithPinResponseCommand: Command {
    typealias CommandResponse = AuthorizeWithPinResponseResponse

    var usesEncryption: Bool { false }
    var accessLevel: AccessLevel { .publicSecureChannel }
    
    private let challenge: Data

    init(challenge: Data) {
        self.challenge = challenge
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<AuthorizeWithPinResponseResponse>) {
        guard let pin = session.environment.accessCode.value,
              pin != UserCodeType.accessCode.defaultValue.getSHA256() else {
            session.pause()
            session.environment.accessCode = UserCode(.accessCode, value: nil)

            DispatchQueue.main.async {
                session.requestUserCodeIfNeeded(.accessCode, showWelcomeBackWarning: true) { result in
                    switch result {
                    case .success:
                        session.resume()
                        self.transceive(in: session, completion: completion)
                    case .failure(let error):
                        session.releaseTag()
                        completion(.failure(error))
                    }
                }
            }

            return
        }

        transceive(in: session, completion: completion)
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let pin = environment.accessCode.value ?? Data()
        let hmacPin = pin.hmacSHA256(input: Data("PIN".utf8) + challenge)

        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.interactionMode, value: AuthorizeMode.pinResponse)
            .append(.pin, value: hmacPin)

        return CommandApdu(.authorize, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> AuthorizeWithPinResponseResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return AuthorizeWithPinResponseResponse(
            accessLevel: try decoder.decode(.accessLevel)
        )
    }
}
