//
//  UserCodeRequest.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A one-shot handle for a pending user code prompt: after the first answer it releases
/// everything the completion captures, so the view state that stores the request never
/// retains the session graph.
public final class UserCodeRequest {
    public let type: UserCodeType
    public let cardId: String?
    public let showForgotButton: Bool
    public private(set) var showWelcomeBackWarning: Bool

    private let isOneShot: Bool
    private var completion: CompletionResult<String>?

    init(
        type: UserCodeType,
        cardId: String? = nil,
        showForgotButton: Bool = false,
        showWelcomeBackWarning: Bool = false,
        isOneShot: Bool = true,
        completion: @escaping CompletionResult<String>
    ) {
        self.type = type
        self.cardId = cardId
        self.showForgotButton = showForgotButton
        self.showWelcomeBackWarning = showWelcomeBackWarning
        self.isOneShot = isOneShot
        self.completion = completion
    }

    public func submit(_ code: String) {
        handle(.success(code))
    }

    public func forgotCode() {
        handle(.failure(.userForgotTheCode))
    }

    public func cancel() {
        handle(.failure(.userCancelled))
    }

    public func handle(_ result: Result<String, TangemSdkError>) {
        guard isOneShot else {
            completion?(result)
            return
        }

        let completion = completion
        self.completion = nil
        completion?(result)
    }

    func acknowledgeWelcomeBack() {
        showWelcomeBackWarning = false
    }
}
