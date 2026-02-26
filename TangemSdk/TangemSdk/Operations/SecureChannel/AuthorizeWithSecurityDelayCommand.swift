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
}

/// First step of the security delay secure channel establishment.
/// Sends an authorize command with `.secureDelay` interaction mode.
/// Returns the card's session public key and attestation signature.
class AuthorizeWithSecurityDelayCommand: Command {
    typealias CommandResponse = AuthorizeWithSecurityDelayResponse

    var preflightReadMode: PreflightReadMode { .none }
    var usesEncryption: Bool { false }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.interactionMode, value: AuthorizeMode.secureDelay)

        return CommandApdu(ins: Instruction.authorize.rawValue, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> AuthorizeWithSecurityDelayResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return AuthorizeWithSecurityDelayResponse(
            pubSessionKeyA: try decoder.decode(.sessionKeyA),
            signAttestA: try decoder.decode(.cardSignature)
        )
    }
}
