//
//  FinalizeReadBackupDataCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class FinalizeReadBackupDataCommand: Command {
    var requiresPasscode: Bool { false }

    private let accessCode: Data

    init(accessCode: Data) {
        self.accessCode = accessCode
    }

    deinit {
        Log.debug("FinalizeReadBackupDataCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .keysImportAvailable {
            return .backupFailedFirmware
        }

        if !card.settings.isBackupAllowed {
            return .backupNotAllowed
        }

        if card.backupStatus == .noBackup {
            return .backupFailedCardNotLinked
        }

        if card.wallets.isEmpty {
            return .backupFailedEmptyWallets
        }

        return nil
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        guard let card = environment.card else {
            throw TangemSdkError.missingPreflightRead
        }

        let tlvBuilder = createTlvBuilder(legacyMode: environment.legacyMode)

        if card.firmwareVersion < .v8 {
            try tlvBuilder
                .append(.cardId, value: environment.card?.cardId)
                .append(.pin, value: accessCode)
        }

        return CommandApdu(.finalizeReadBackupData, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SuccessResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return SuccessResponse(cardId: try decoder.decode(.cardId))
    }
}
