//
//  ReadMasterSecretCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct ReadMasterSecretResponse: JSONStringConvertible {
    public let masterSecret: Card.MasterSecret?
}

/// This command reads master secret from the Tangem Card.
public final class ReadMasterSecretCommand: Command {
    public var preflightReadMode: PreflightReadMode { .readCardOnly }

    public init() {}

    deinit {
        Log.debug("ReadMasterSecretCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        guard card.firmwareVersion >= .v8 else {
            return TangemSdkError.notSupportedFirmwareVersion
        }

        return nil
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.interactionMode, value: ReadMode.masterSecret)

        return CommandApdu(.read, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadMasterSecretResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        let masterSecret = MasterSecretDeserializer().deserializeMasterSecret(from: decoder)
        return ReadMasterSecretResponse(masterSecret: masterSecret)
    }
}
