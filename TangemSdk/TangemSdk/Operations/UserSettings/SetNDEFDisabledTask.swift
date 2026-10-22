//
//  SetNDEFDisabledTask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public final class SetNDEFDisabledTask: CardSessionRunnable {
    public var preflightReadMode: PreflightReadMode { .readCardOnly }

    private let isDisabled: Bool

    /// Default initializer
    /// - Parameter isDisabled: Whether NDEF reading feature is disabled on the card
    public init(isDisabled: Bool) {
        self.isDisabled = isDisabled
    }

    deinit {
        Log.debug("SetNDEFDisabledTask deinit")
    }

    public func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        if card.firmwareVersion < .v8 {
            completion(.failure(.notSupportedFirmwareVersion))
            return
        }

        var userSettings = card.userSettings
        userSettings.isNDEFDisabled = isDisabled

        let setUserSettingsCommand = SetUserSettingsCommand(settings: userSettings)
        setUserSettingsCommand.run(in: session) { result in
            switch result {
            case .success(let response):
                completion(.success(SuccessResponse(cardId: response.cardId)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
