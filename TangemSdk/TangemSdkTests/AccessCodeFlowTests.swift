//
//  AccessCodeFlowTests.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

@MainActor
final class AccessCodeFlowTests: XCTestCase {
    func testResetStateMapsToScreen() {
        let screens = ResetPinService.State.allCases.map { $0.analyticsScreen }

        XCTAssertEqual(screens, [
            .resetCodesNewCode,
            .resetCodesScanResetCard,
            .resetCodesScanConfirmationCard,
            .resetCodesWriteResetCard,
            .resetCodesSuccess,
        ])
    }

    func testFlowReadsConfig() {
        let handler = HandlerMock()
        var config = Config()
        config.usesNewAccessCodeDesign = true
        config.supportHandler = handler

        let flow = AccessCodeFlow(config: config)

        XCTAssertTrue(flow.usesNewDesign)
        XCTAssertTrue(flow.isSupportAvailable)
        XCTAssertFalse(AccessCodeFlow(config: Config()).usesNewDesign)
        XCTAssertFalse(AccessCodeFlow(config: Config()).isSupportAvailable)
    }

    func testPasscodeScopeIsInert() {
        let handler = HandlerMock()
        var config = makeConfig(handler)
        config.usesNewAccessCodeDesign = true
        let flow = AccessCodeFlow(config: config)

        let accessCodeFlow = flow.scoped(to: .accessCode)
        let passcodeFlow = flow.scoped(to: .passcode)
        passcodeFlow.deliverTap(for: Result<String, TangemSdkError>.failure(.userForgotTheCode), on: .enterAccessCode)
        passcodeFlow.requestSupport(from: .enterAccessCode)
        passcodeFlow.openPendingSupport()

        XCTAssertTrue(accessCodeFlow === flow)
        XCTAssertFalse(passcodeFlow.usesNewDesign)
        XCTAssertFalse(passcodeFlow.isSupportAvailable)
        XCTAssertTrue(handler.events.isEmpty)
        XCTAssertTrue(handler.supportScreens.isEmpty)
    }

    func testTapsMapToButtons() {
        let handler = HandlerMock()
        let flow = AccessCodeFlow(config: makeConfig(handler))

        flow.deliverTap(for: Result<String, TangemSdkError>.success("code"), on: .enterAccessCode)
        flow.deliverTap(for: Result<String, TangemSdkError>.failure(.userForgotTheCode), on: .enterAccessCode)
        flow.deliverTap(for: Result<Bool, TangemSdkError>.failure(.userCancelled), on: .resetCodesScanResetCard)
        flow.deliverTap(for: Result<Bool, TangemSdkError>.failure(.unknownError), on: .resetCodesScanResetCard)

        XCTAssertEqual(handler.events, [
            .buttonTapped(.continue, screen: .enterAccessCode),
            .buttonTapped(.forgotCode, screen: .enterAccessCode),
            .buttonTapped(.close, screen: .resetCodesScanResetCard),
        ])
    }

    func testSupportLogsOnceAndOpensAfterwards() {
        let handler = HandlerMock()
        let flow = AccessCodeFlow(config: makeConfig(handler))

        flow.requestSupport(from: .resetCodesNewCode)
        flow.deliverTap(for: Result<String, TangemSdkError>.failure(.userCancelled), on: .resetCodesNewCode)

        XCTAssertEqual(handler.events, [.buttonTapped(.support, screen: .resetCodesNewCode)])
        XCTAssertTrue(handler.supportScreens.isEmpty)

        flow.openPendingSupport()
        flow.openPendingSupport()

        XCTAssertEqual(handler.supportScreens, [.resetCodesNewCode])
    }

    func testOpenPendingSupportWithoutRequestDoesNothing() {
        let handler = HandlerMock()
        let flow = AccessCodeFlow(config: makeConfig(handler))

        flow.openPendingSupport()

        XCTAssertTrue(handler.supportScreens.isEmpty)
    }

    func testFailureLoggingSkipsCancellation() async {
        let handler = HandlerMock()
        let flow = AccessCodeFlow(config: makeConfig(handler))

        flow.logFailure(.userCancelled)
        flow.logFailure(.unknownError)
        flow.log(.resetCodesFinished)
        await waitForMainActorTasks(handler: handler, count: 2)

        XCTAssertEqual(handler.events, [
            .resetCodesFailed(errorCode: TangemSdkError.unknownError.code),
            .resetCodesFinished,
        ])
    }

    func testHandlersAreNotRetained() {
        var handler: HandlerMock? = HandlerMock()
        weak let weakHandler = handler
        let flow = AccessCodeFlow(config: makeConfig(handler!))

        handler = nil

        XCTAssertNil(weakHandler)
        XCTAssertFalse(flow.isSupportAvailable)
    }

    private func makeConfig(_ handler: HandlerMock) -> Config {
        var config = Config()
        config.supportHandler = handler
        config.analyticsHandler = handler
        return config
    }

    private func waitForMainActorTasks(handler: HandlerMock, count: Int) async {
        for _ in 0 ..< 100 where handler.events.count < count {
            await Task.yield()
        }
    }
}

@MainActor
private final class HandlerMock: TangemSdkSupportHandler, TangemSdkAnalyticsHandler {
    private(set) var events: [TangemSdkAnalyticsEvent] = []
    private(set) var supportScreens: [TangemSdkScreen] = []

    func openSupport(from screen: TangemSdkScreen) {
        supportScreens.append(screen)
    }

    func log(_ event: TangemSdkAnalyticsEvent) {
        events.append(event)
    }
}
