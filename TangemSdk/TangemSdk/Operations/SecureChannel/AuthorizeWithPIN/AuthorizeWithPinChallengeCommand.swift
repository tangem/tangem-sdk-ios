//
//  AuthorizeWithPinCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

// MARK: - Challenge

struct AuthorizeWithPinChallengeResponse {
    let challengeWithXor: Data
}

/// Requests a challenge from the card for PIN verification.
class AuthorizeWithPinChallengeCommand: Command {
    typealias CommandResponse = AuthorizeWithPinChallengeResponse

    var preflightReadMode: PreflightReadMode { .none }
    var cardSessionEncryption: CardSessionEncryption { .publicSecureChannel }

    deinit {
        Log.debug("AuthorizeWithPinChallengeCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .v8 {
            return TangemSdkError.notSupportedFirmwareVersion
        }

        return nil
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<AuthorizeWithPinChallengeResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.interactionMode, value: AuthorizeMode.pinChallenge)

        return CommandApdu(.authorize, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> AuthorizeWithPinChallengeResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return AuthorizeWithPinChallengeResponse(
            challengeWithXor: try decoder.decode(.challenge)
        )
    }
}
