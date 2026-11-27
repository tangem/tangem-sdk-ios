//
//  ExampleAccessCodeHooks.swift
//  TangemSdkExample
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

@MainActor
final class ExampleAccessCodeHooks: TangemSdkSupportHandler, TangemSdkAnalyticsHandler {
    var onMessage: ((String) -> Void)?

    func openSupport(from screen: TangemSdkScreen) {
        report("Support opened from \(screen)")
    }

    func log(_ event: TangemSdkAnalyticsEvent) {
        report("SDK analytics: \(event)")
    }

    private func report(_ message: String) {
        print(message)
        onMessage?(message)
    }
}
