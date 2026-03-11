//
//  CreateMasterSecretCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 06/03/26.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// This command will create a new master secret on the card.
/// A key pair is generated or imported and securely stored in the card.
public final class CreateMasterSecretCommand: Command {
    var requiresPasscode: Bool { true }

    private let privateKey: ExtendedPrivateKey?

    /// Use this initializer to import a key.
    /// - Parameter privateKey: A private key to import. Creates a new master secret on the card if nil
    public init(privateKey: ExtendedPrivateKey? = nil) {
        self.privateKey = privateKey
    }

    deinit {
        Log.debug("CreateMasterSecretCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .v8 {
            return .notSupportedFirmwareVersion
        }

        if card.masterSecret != nil {
            return TangemSdkError.alreadyCreated
        }

        /// It's impossible to create backup without creating master secret. If backup is already created or started, master secret must be created too.
        if let backupStatus = card.backupStatus, backupStatus != .noBackup {
            return TangemSdkError.alreadyCreated
        }

        if privateKey != nil, !card.settings.isKeysImportAllowed {
            return TangemSdkError.keysImportDisabled
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

    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        if case .invalidState = error {
            return .alreadyCreated
        }

        return error
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = createTlvBuilder(legacyMode: environment.legacyMode)
        try tlvBuilder.append(.interactionMode, value: ManageMasterSecretMode.create)

        if let privateKey {
            try tlvBuilder.append(.walletPrivateKey, value: privateKey.privateKey)
            try tlvBuilder.append(.walletHDChain, value: privateKey.chainCode)
        }

        return CommandApdu(.manageMasterSecret, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadMasterSecretResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        let masterSecret = MasterSecretDeserializer().deserializeMasterSecret(from: decoder)
        return ReadMasterSecretResponse(masterSecret: masterSecret)
    }
}
