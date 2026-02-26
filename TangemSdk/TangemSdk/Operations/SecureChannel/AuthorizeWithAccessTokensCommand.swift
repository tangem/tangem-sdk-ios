//
//  AuthorizeWithAccessTokensCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20/02/2026.
//

import Foundation

struct AuthorizeWithAccessTokenResponse {
    let challengeA: Data
    let hmacAttestA: Data
}

/// First step of the access token secure channel establishment.
/// Sends an authorize command with `.accessToken` interaction mode.
/// Returns a challenge and HMAC attestation from the card.
class AuthorizeWithAccessTokensCommand: Command {
    typealias CommandResponse = AuthorizeWithAccessTokenResponse

    var preflightReadMode: PreflightReadMode { .none }
    var usesEncryption: Bool { false }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId )
            .append(.interactionMode, value: AuthorizeMode.accessToken)

        return CommandApdu(ins: Instruction.authorize.rawValue, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> AuthorizeWithAccessTokenResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return AuthorizeWithAccessTokenResponse(
            challengeA: try decoder.decode(.challenge),
            hmacAttestA: try decoder.decode(.hmac)
        )
    }
}
