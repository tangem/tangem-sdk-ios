//
//  MainViewModel.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

typealias MainViewModel = ViewModel<SessionViewState>

extension MainViewModel {
    func handleWelcomeBackResult(
        _ result: Result<Bool, TangemSdkError>,
        type: UserCodeType,
        cardId: String?,
        showForgotButton: Bool,
        completion: @escaping CompletionResult<String>
    ) {
        switch result {
        case .success(true):
            viewState = .requestCode(
                type,
                cardId: cardId,
                showForgotButton: showForgotButton,
                showWelcomeBackWarning: false,
                completion: completion
            )
        case .success(false), .failure:
            completion(.failure(.userCancelled))
        }
    }
}
