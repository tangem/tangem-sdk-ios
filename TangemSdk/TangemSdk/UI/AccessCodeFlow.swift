//
//  AccessCodeFlow.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class AccessCodeFlow {
    let usesNewDesign: Bool
    let showsResetCodesIntro: Bool

    var isSupportAvailable: Bool { handlers.support != nil }

    private let handlers: Handlers
    private var pendingSupportScreen: TangemSdkScreen?

    nonisolated init(config: Config) {
        usesNewDesign = config.usesNewAccessCodeDesign
        showsResetCodesIntro = config.usesNewAccessCodeDesign && config.showsResetCodesIntro
        handlers = Handlers(support: config.supportHandler, analytics: config.analyticsHandler)
    }

    nonisolated func log(_ events: TangemSdkAnalyticsEvent...) {
        Task { @MainActor in
            events.forEach(self.deliver)
        }
    }

    nonisolated func logFailure(_ error: TangemSdkError) {
        guard !error.isUserCancelled else { return }

        log(.resetCodesFailed(errorCode: error.code))
    }

    func requestSupport(from screen: TangemSdkScreen) {
        deliver(.buttonTapped(.support, screen: screen))
        pendingSupportScreen = screen
    }

    func openPendingSupport() {
        guard let screen = pendingSupportScreen else { return }

        pendingSupportScreen = nil
        handlers.support?.openSupport(from: screen)
    }

    func deliver(_ event: TangemSdkAnalyticsEvent) {
        handlers.analytics?.log(event)
    }

    func deliverTap<Value>(for result: Result<Value, TangemSdkError>, on screen: TangemSdkScreen) {
        let button: TangemSdkButton?

        switch result {
        case .success:
            button = .continue
        case .failure(.userForgotTheCode):
            button = .forgotCode
        case .failure(.userCancelled):
            button = pendingSupportScreen == nil ? .close : nil
        case .failure:
            button = nil
        }

        if let button {
            deliver(.buttonTapped(button, screen: screen))
        }
    }
}

private extension AccessCodeFlow {
    struct Handlers: Sendable {
        weak var support: TangemSdkSupportHandler?
        weak var analytics: TangemSdkAnalyticsHandler?
    }
}

extension EnvironmentValues {
    @Entry var accessCodeFlow: AccessCodeFlow? = nil
    @Entry var accessCodeScreen: TangemSdkScreen? = nil
}

extension View {
    func accessCodeScreen(_ screen: TangemSdkScreen, flow: AccessCodeFlow?) -> some View {
        environment(\.accessCodeFlow, flow)
            .environment(\.accessCodeScreen, screen)
            .task(id: screen) {
                flow?.deliver(.screenOpened(screen))
            }
    }
}
