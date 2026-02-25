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

    private let challenge: Data

    init(challenge: Data) {
        self.challenge = challenge
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let pin = environment.accessCode.value ?? Data()
        let hmacPin = pin.hmacSHA256(input: Data("PIN".utf8) + challenge)

        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.interactionMode, value: AuthorizeMode.pinResponse)
            .append(.pin, value: hmacPin)

        return CommandApdu(ins: Instruction.authorize.rawValue, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> AuthorizeWithPinResponseResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return AuthorizeWithPinResponseResponse(
            accessLevel: try decoder.decode(.accessLevel)
        )
    }
}
