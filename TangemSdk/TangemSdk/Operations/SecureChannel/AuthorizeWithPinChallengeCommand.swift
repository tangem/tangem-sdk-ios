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

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.interactionMode, value: AuthorizeMode.pinChallenge)

        return CommandApdu(ins: Instruction.authorize.rawValue, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> AuthorizeWithPinChallengeResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return AuthorizeWithPinChallengeResponse(
            challenge: try decoder.decode(.challenge)
        )
    }
}
