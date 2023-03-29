//
//  SetResettingUserCodesAllowedTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 28.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public final class SetResettingUserCodesAllowedTask: CardSessionRunnable {
    public var preflightReadMode: PreflightReadMode { .readCardOnly }
    
    private let isResettingUserCodesAllowed: Bool
    
    /// Default initializer
    /// - Parameter isResettingUserCodesAllowed: Is this card can reset user codes on tte other linked card or not
    public init(isResettingUserCodesAllowed: Bool) {
        self.isResettingUserCodesAllowed = isResettingUserCodesAllowed
    }
    
    deinit {
        Log.debug("SetResettingUserCodesAllowedTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        var userSettings = UserSettings(from: card.settings)
        userSettings.isResettingUserCodesAllowed = isResettingUserCodesAllowed
        
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
