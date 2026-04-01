//
//  SetUserSettingsCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 28.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `SetUserSettingsCommand`. COS v.6.16+
struct SetUserSettingsCommandResponse: JSONStringConvertible {
    /// Unique Tangem card ID number.
    let cardId: String
    /// The mask that was set
    let settings: Card.UserSettings
}

/// Set user settings on a card. COS v.6.16+
class SetUserSettingsCommand: Command {
    var preflightReadMode: PreflightReadMode { .readCardOnly }
    var cardSessionEncryption: CardSessionEncryption { .secureChannelWithPIN }

    private let settings: Card.UserSettings

    init(settings: Card.UserSettings) {
        self.settings = settings
    }

    deinit {
        Log.debug("SetUserSettingsCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        guard card.firmwareVersion >= .keysImportAvailable else {
            return TangemSdkError.notSupportedFirmwareVersion
        }

        return nil
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<SetUserSettingsCommandResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                session.environment.card?.userSettings = response.settings
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

        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.userSettingsMask, value: settings.mask)

        if shouldAddPin(environment.accessCode, firmwareVersion: card.firmwareVersion) {
            try tlvBuilder.append(.pin, value: environment.accessCode.value)
        }

        if shouldAddPin(environment.passcode, firmwareVersion: card.firmwareVersion) {
            try tlvBuilder.append(.pin2, value: environment.passcode.value)
        }

        if card.firmwareVersion < .v8 {
            try tlvBuilder.append(.cardId, value: environment.card?.cardId)
        }

        return CommandApdu(.setUserSettings, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SetUserSettingsCommandResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        let mask: UserSettingsMask = try decoder.decode(.userSettingsMask)
        return SetUserSettingsCommandResponse(cardId: try decoder.decode(.cardId), settings: .init(from: mask))
    }
}
