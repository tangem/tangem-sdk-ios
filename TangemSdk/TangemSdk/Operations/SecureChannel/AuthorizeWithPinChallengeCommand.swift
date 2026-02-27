//
//  AuthorizeWithPinCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20/02/2026.
//

import Foundation

// MARK: - Challenge

struct AuthorizeWithPinChallengeResponse {
    let challenge: Data
}

/// Requests a challenge from the card for PIN verification.
class AuthorizeWithPinChallengeCommand: Command {
    typealias CommandResponse = AuthorizeWithPinChallengeResponse

    var preflightReadMode: PreflightReadMode { .none }
    var usesEncryption: Bool { false }

    var accessLevel: AccessLevel { .publicSecureChannel }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.interactionMode, value: AuthorizeMode.pinChallenge)

        return CommandApdu(.authorize, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> AuthorizeWithPinChallengeResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return AuthorizeWithPinChallengeResponse(
            challenge: try decoder.decode(.challenge)
        )
    }
}
