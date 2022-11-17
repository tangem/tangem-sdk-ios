//
//  LAContext+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import LocalAuthentication

public extension LAContext {
    static func `default`() -> LAContext {
        let context = LAContext()
        context.localizedFallbackTitle = "" // hiding the "Enter Password" fallback button
        return context
    }
}
