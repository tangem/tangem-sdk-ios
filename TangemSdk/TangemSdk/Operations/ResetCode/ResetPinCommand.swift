//
//  ResetPinCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

final class ResetPinCommand: Command {
    var requiresPasscode: Bool { false }
    var preflightReadMode: PreflightReadMode { .readCardOnly }
    var cardSessionEncryption: CardSessionEncryption { .publicSecureChannel }

    private let accessCode: Data
    private let passcode: Data

    init(accessCode: Data, passcode: Data) {
        self.accessCode = accessCode
        self.passcode = passcode
    }

    deinit {
        Log.debug("ResetPinCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .backupAvailable {
            return .notSupportedFirmwareVersion
        }

        guard let backupStatus = card.backupStatus,
              backupStatus.isActive else {
            return TangemSdkError.noActiveBackup
        }

        return nil
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                session.environment.accessCode = UserCode(.accessCode, value: self.accessCode)
                session.environment.passcode = UserCode(.passcode, value: self.passcode)
                session.resetAccessTokens()
                completion(.success(response))
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

        if card.firmwareVersion < .v8 {
            try tlvBuilder
                .append(.cardId, value: environment.card?.cardId)
                .append(.newPin, value: accessCode)
                .append(.newPin2, value: passcode)
                .append(.hash, value: (accessCode + passcode).getSHA256())
        } else {
            try tlvBuilder
                .append(.newPin, value: accessCode)
                .append(.hash, value: accessCode.getSHA256())
        }

        return CommandApdu(.setPin, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SuccessResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return SuccessResponse(cardId: try decoder.decode(.cardId))
    }
}
