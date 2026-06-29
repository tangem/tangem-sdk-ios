//
//  ResetBackupCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct ResetBackupResponse {
    let cardId: String
    let backupStatus: Card.BackupRawStatus
    let settingsMask: CardSettingsMask
    let isDefaultAccessCode: Bool
    let isDefaultPasscode: Bool
}

public final class ResetBackupCommand: Command {
    public var requiresPasscode: Bool { true }
    public var preflightReadMode: PreflightReadMode { .fullCardRead }

    public init() {}

    deinit {
        Log.debug("ResetBackupCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .backupAvailable {
            return .notSupportedFirmwareVersion
        }

        guard let backupStatus = card.backupStatus, backupStatus.canResetBackup else {
            return TangemSdkError.noActiveBackup
        }

        guard !card.wallets.contains(where: { $0.hasBackup }) else {
            return TangemSdkError.resetBackupFailedHasBackedUpWallets
        }

        return nil
    }

    public func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                if response.backupStatus != .noBackup {
                    completion(.failure(.unknownError))
                    return
                }

                session.environment.card?.backupStatus = .noBackup
                session.environment.card?.isAccessCodeSet = !response.isDefaultAccessCode
                session.environment.card?.isPasscodeSet = !response.isDefaultPasscode
                session.environment.accessCode = response.isDefaultAccessCode ? UserCode(.accessCode) : UserCode(.accessCode, value: nil)
                session.environment.passcode = response.isDefaultPasscode ? UserCode(.passcode) : UserCode(.passcode, value: nil)

                if let settings = session.environment.card?.settings {
                    session.environment.card?.settings = settings.updated(with: response.settingsMask)
                }

                completion(.success(SuccessResponse(cardId: response.cardId)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        guard let card = environment.card else {
            throw TangemSdkError.missingPreflightRead
        }

        let tlvBuilder = createTlvBuilder(legacyMode: environment.legacyMode)

        if shouldAddPin(environment.accessCode, firmwareVersion: card.firmwareVersion) {
            try tlvBuilder.append(.pin, value: environment.accessCode.value)
        }

        if shouldAddPin(environment.passcode, firmwareVersion: card.firmwareVersion) {
            try tlvBuilder.append(.pin2, value: environment.passcode.value)
        }

        if card.firmwareVersion < .v8 {
            try tlvBuilder.append(.cardId, value: environment.card?.cardId)
        }

        return CommandApdu(.backupReset, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ResetBackupResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return ResetBackupResponse(
            cardId: try decoder.decode(.cardId),
            backupStatus: try decoder.decode(.backupStatus),
            settingsMask: try decoder.decode(.settingsMask),
            isDefaultAccessCode: try decoder.decode(.pinIsDefault),
            isDefaultPasscode: try decoder.decode(.pin2IsDefault)
        )
    }
}

private extension Card.BackupStatus {
    var canResetBackup: Bool {
        switch self {
        case .active, .cardLinked:
            return true
        case .noBackup:
            return false
        }
    }
}
