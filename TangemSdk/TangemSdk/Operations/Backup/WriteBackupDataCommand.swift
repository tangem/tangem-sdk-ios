//
//  WriteBackupDataCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Response from the Tangem card after `WriteBackupDataCommand`.
struct WriteBackupDataResponse {
    /// Unique Tangem card ID number
    let cardId: String
    let backupStatus: Card.BackupRawStatus
}

final class WriteBackupDataCommand: Command {
    var requiresPasscode: Bool { false }

    private let backupData: [EncryptedBackupData]
    private let accessCode: Data

    private var index = 0

    init(backupData: [EncryptedBackupData], accessCode: Data) {
        self.backupData = backupData
        self.accessCode = accessCode
    }

    deinit {
        Log.debug("WriteBackupDataCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .backupAvailable {
            return .backupFailedFirmware
        }

        if !card.settings.isBackupAllowed {
            return .backupNotAllowed
        }

        if card.backupStatus == .noBackup {
            return .backupFailedCardNotLinked
        }

        return nil
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<WriteBackupDataResponse>) {
        writeData(in: session, completion: completion)
    }

    private func writeData(in session: CardSession, completion: @escaping CompletionResult<WriteBackupDataResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                if self.index == self.backupData.count - 1 {
                    if case .cardLinked(cardsCount: let cardsCount) = session.environment.card?.backupStatus {
                        session.environment.card?.backupStatus = try? Card.BackupStatus(from: response.backupStatus, cardsCount: cardsCount)
                    }

                    completion(.success(response))
                    return
                }

                self.index += 1
                self.writeData(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        guard let card = environment.card else {
            throw TangemSdkError.missingPreflightRead
        }

        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.salt, value: backupData[index].salt)
            .append(.data, value: backupData[index].data)

        if card.firmwareVersion < .v8 {
            try tlvBuilder
                .append(.cardId, value: environment.card?.cardId)
                .append(.pin, value: accessCode)
        }

        return CommandApdu(.writeBackupData, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> WriteBackupDataResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)

        return WriteBackupDataResponse(
            cardId: try decoder.decode(.cardId),
            backupStatus: try decoder.decode(.backupStatus)
        )
    }
}
