//
//  OpenSessionWithAccessTokenCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20/02/2026.
//

import Foundation

struct OpenSessionWithAccessTokenResponse {
    let accessLevel: AccessLevel
    let signAttestSession: Data
}

/// Second step of the access token secure channel establishment.
/// Opens an encrypted session using challenge-response with access tokens.
class OpenSessionWithAccessTokenCommand: ApduSerializable {
    typealias CommandResponse = OpenSessionWithAccessTokenResponse

    private let challengeB: Data
    private let hmacAttestB: Data

    init(challengeB: Data, hmacAttestB: Data) {
        self.challengeB = challengeB
        self.hmacAttestB = hmacAttestB
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.challenge, value: challengeB)
            .append(.hmac, value: hmacAttestB)

        return CommandApdu(
            ins: Instruction.openSession.rawValue,
            p2: EncryptionMode.ccmWithAccessToken.byteValue,
            tlv: tlvBuilder.serialize()
        )
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> OpenSessionWithAccessTokenResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return OpenSessionWithAccessTokenResponse(
            accessLevel: try decoder.decode(.accessLevel),
            signAttestSession: try decoder.decode(.cardSignature)
        )
    }
}
