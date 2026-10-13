//
//  WelcomeBackRequest.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 13.10.2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public final class WelcomeBackRequest {
    private var completion: CompletionResult<Void>?

    init(completion: @escaping CompletionResult<Void>) {
        self.completion = completion
    }

    public func confirm() {
        handle(.success(()))
    }

    public func cancel() {
        handle(.failure(.userCancelled))
    }

    private func handle(_ result: Result<Void, TangemSdkError>) {
        let completion = completion
        self.completion = nil
        completion?(result)
    }
}
