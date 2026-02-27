//
//  ManageAccessTokensCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 27/02/2026.
//

import Foundation

struct ManageAccessTokensResponse {
    let accessToken: Data
    let identifyToken: Data
}

enum ManageAccessTokensMode: Byte, InteractionMode {
    case get = 0x00
    case renew = 0x01
    case reset = 0x02
}

/// Manages access tokens on the card: get, renew, or reset.
/// Requires PIN verification (user-level access).
class ManageAccessTokensCommand: Command {
    typealias CommandResponse = ManageAccessTokensResponse

    private let mode: ManageAccessTokensMode

    init(mode: ManageAccessTokensMode) {
        self.mode = mode
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.interactionMode, value: mode)

        return CommandApdu(ins: Instruction.manageAccessTokens.rawValue, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ManageAccessTokensResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return ManageAccessTokensResponse(
            accessToken: try decoder.decode(.accessToken),
            identifyToken: try decoder.decode(.identifyToken)
        )
    }
}
