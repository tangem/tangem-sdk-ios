//
//  TangemSdk+Concurrency.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension CardSessionRunnable {
    /// Async/await wrapper for the `prepare` method.
    /// - Parameter session: You can use view delegate methods at this point, but you cannot execute commands yet.
    func prepare(_ session: CardSession) async throws(TangemSdkError) {
        let result: Result<Void, TangemSdkError> = await withCheckedContinuation { continuation in
            prepare(session) { continuation.resume(returning: $0) }
        }

        try result.get()
    }

    /// Async/await wrapper for the `run` method.
    /// - Parameter session: You can run commands in this session
    /// - Returns: `Response`
    func run(in session: CardSession) async throws(TangemSdkError) -> Response {
        let result: Result<Response, TangemSdkError> = await withCheckedContinuation { continuation in
            run(in: session) { continuation.resume(returning: $0) }
        }

        return try result.get()
    }
}

public extension TangemSdk {
    /// Async/await wrapper for the `startSession` method.
    /// - Parameters:
    ///   - runnable: A custom task, adopting `CardSessionRunnable` protocol
    ///   - cardId: CID, Unique Tangem card ID number. If not nil, the SDK will check that you tapped the card with this cardID and will return the `wrongCard` error otherwise
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - accessCode: Access code that will be used for a card session initialization. If nil, Tangem SDK will handle it automatically.
    /// - Note: Cancelling the calling task does not stop the NFC session. It runs to completion, until the card is tapped or the user dismisses the system sheet.
    /// - Returns: `T.Response`
    func startSession<T: CardSessionRunnable>(
        with runnable: T,
        cardId: String? = nil,
        initialMessage: Message? = nil,
        accessCode: String? = nil
    ) async throws(TangemSdkError) -> T.Response {
        let result: Result<T.Response, TangemSdkError> = await withCheckedContinuation { continuation in
            runOnMainThread {
                self.startSession(
                    with: runnable,
                    cardId: cardId,
                    initialMessage: initialMessage,
                    accessCode: accessCode
                ) { continuation.resume(returning: $0) }
            }
        }

        return try result.get()
    }

    /// Async/await wrapper for the `startSession` method.
    /// - Parameters:
    ///   - runnable: A custom task, adopting `CardSessionRunnable` protocol
    ///   - filter: Filters card to be read. Optional.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - accessCode: Access code that will be used for a card session initialization. If nil, Tangem SDK will handle it automatically.
    /// - Note: Cancelling the calling task does not stop the NFC session. It runs to completion, until the card is tapped or the user dismisses the system sheet.
    /// - Returns: `T.Response`
    func startSession<T: CardSessionRunnable>(
        with runnable: T,
        filter: SessionFilter?,
        initialMessage: Message? = nil,
        accessCode: String? = nil
    ) async throws(TangemSdkError) -> T.Response {
        let result: Result<T.Response, TangemSdkError> = await withCheckedContinuation { continuation in
            runOnMainThread {
                self.startSession(
                    with: runnable,
                    filter: filter,
                    initialMessage: initialMessage,
                    accessCode: accessCode
                ) { continuation.resume(returning: $0) }
            }
        }

        return try result.get()
    }
}

/// A nonisolated async function does not inherit the caller's executor, so the session would otherwise start on
/// the cooperative pool, while `TangemSdk` keeps its session state unsynchronized and drives the UI from here.
/// The inline branch keeps the call in place once `nonisolated(nonsending)` makes that inheritance the default.
private func runOnMainThread(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async(execute: block)
    }
}
