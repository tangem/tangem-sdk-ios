//
//  ReadMasterSecretCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 06/03/26.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct ReadMasterSecretResponse: JSONStringConvertible {
    public let masterSecret: Card.MasterSecret?
}

/// This command reads master secret from the Tangem Card.
final class ReadMasterSecretCommand: Command {
    var preflightReadMode: PreflightReadMode { .none }

    private let derivationPath: DerivationPath?

    init(derivationPath: DerivationPath? = nil) {
        self.derivationPath = derivationPath
    }

    deinit {
        Log.debug("ReadMasterSecretCommand deinit")
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = createTlvBuilder(legacyMode: environment.legacyMode)
        try tlvBuilder.append(.interactionMode, value: ReadMode.masterSecret)

        if let derivationPath {
            try tlvBuilder.append(.walletHDPath, value: derivationPath)
        }

        return CommandApdu(.read, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadMasterSecretResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        let masterSecret = MasterSecretDeserializer().deserializeMasterSecret(from: decoder)
        return ReadMasterSecretResponse(masterSecret: masterSecret)
    }
}
