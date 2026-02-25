//
//  OpenSessionWithSecurityDelayCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20/02/2026.
//

import Foundation

struct OpenSessionWithSecurityDelayResponse {
    let accessLevel: AccessLevel
}

/// Second step of the security delay secure channel establishment.
/// Opens an encrypted session using ECDH key exchange.
class OpenSessionWithSecurityDelayCommand: ApduSerializable {
    typealias CommandResponse = OpenSessionWithSecurityDelayResponse

    private let sessionKeyB: Data

    init(sessionKeyB: Data) {
        self.sessionKeyB = sessionKeyB
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.sessionKeyB, value: sessionKeyB)

        return CommandApdu(
            ins: Instruction.openSession.rawValue,
            p2: EncryptionMode.ccmWithSecurityDelay.byteValue,
            tlv: tlvBuilder.serialize()
        )
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> OpenSessionWithSecurityDelayResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        
        return OpenSessionWithSecurityDelayResponse(
            accessLevel: try decoder.decode(.accessLevel)
        )
    }
}
