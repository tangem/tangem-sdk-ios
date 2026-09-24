//
//  ResetCodesRequest.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A handle for a pending reset codes interaction. Stays invokable because the flow retries
/// after recoverable errors, so the completion must capture the flow controller weakly —
/// the stored view state would retain it otherwise.
final class ResetCodesRequest {
    let type: UserCodeType
    let state: ResetPinService.State
    let cardId: String?

    private let completion: CompletionResult<Bool>

    init(
        type: UserCodeType,
        state: ResetPinService.State,
        cardId: String?,
        completion: @escaping CompletionResult<Bool>
    ) {
        self.type = type
        self.state = state
        self.cardId = cardId
        self.completion = completion
    }

    func handle(_ result: Result<Bool, TangemSdkError>) {
        completion(result)
    }
}
