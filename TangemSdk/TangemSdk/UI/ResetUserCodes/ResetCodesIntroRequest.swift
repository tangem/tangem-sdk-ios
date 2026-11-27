//
//  ResetCodesIntroRequest.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class ResetCodesIntroRequest {
    private let completion: CompletionResult<Void>

    init(completion: @escaping CompletionResult<Void>) {
        self.completion = completion
    }

    func handle(_ result: Result<Void, TangemSdkError>) {
        completion(result)
    }
}
