//
//  SetPinRequiredTask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public final class SetPinRequiredTask: CardSessionRunnable {
    public var preflightReadMode: PreflightReadMode { .readCardOnly }

    private let isRequired: Bool

    /// Default initializer
    /// - Parameter isRequired: Whether PIN is required to open session for v8+ cards
    public init(isRequired: Bool) {
        self.isRequired = isRequired
    }

    deinit {
        Log.debug("SetPinRequiredTask deinit")
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
        userSettings.isPINRequired = isRequired

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
