//
//  AuthorizeWithPinResponseCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24/02/2026.
//

import Foundation

// MARK: - Response

struct AuthorizeWithPinResponseCommandResponse {
    let accessLevel: AccessLevel
}

/// Sends the HMAC-based PIN response to the card for verification.
class AuthorizeWithPinResponseCommand: Command {
    typealias CommandResponse = AuthorizeWithPinResponseCommandResponse

    var cardSessionEncryption: CardSessionEncryption { .publicSecureChannel }

    private let challengeWithXor: Data

    init(challengeWithXor: Data) {
        self.challengeWithXor = challengeWithXor
    }

    deinit {
        Log.debug("AuthorizeWithPinResponseCommand deinit")
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        guard let pin = environment.accessCode.value else {
            throw TangemSdkError.serializeCommandError
        }

        let pinChallenge = try challengeWithXor.xor(with: pin)
        let hmacPin = challengeWithXor.hmacSHA256(input: Data("PIN".utf8) + pinChallenge)

        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.interactionMode, value: AuthorizeMode.pinResponse)
            .append(.pin, value: hmacPin)

        return CommandApdu(.authorize, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> AuthorizeWithPinResponseCommandResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return AuthorizeWithPinResponseCommandResponse(
            accessLevel: try decoder.decode(.accessLevel)
        )
    }
}
