//
//  PurgeMasterSecretCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// This command will purge the master secret on the card.
public final class PurgeMasterSecretCommand: Command {
    var requiresPasscode: Bool { true }

    public init() {}

    deinit {
        Log.debug("PurgeMasterSecretCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .v8 {
            return .notSupportedFirmwareVersion
        }

        return nil
    }

    public func run(in session: CardSession, completion: @escaping CompletionResult<ReadMasterSecretResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                session.environment.card?.masterSecret = response.masterSecret
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = createTlvBuilder(legacyMode: environment.legacyMode)
        try tlvBuilder.append(.interactionMode, value: ManageMasterSecretMode.purge)
        return CommandApdu(.manageMasterSecret, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadMasterSecretResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        let masterSecret = MasterSecretDeserializer().deserializeMasterSecret(from: decoder)
        return ReadMasterSecretResponse(masterSecret: masterSecret)
    }
}
