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
public final class ResetCodesRequest {
    public let type: UserCodeType
    public let state: ResetPinService.State
    public let cardId: String?

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

    public func proceed() {
        handle(.success(true))
    }

    public func cancel() {
        handle(.failure(.userCancelled))
    }

    func handle(_ result: Result<Bool, TangemSdkError>) {
        completion(result)
    }
}
