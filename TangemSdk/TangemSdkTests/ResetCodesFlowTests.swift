//
//  ResetCodesFlowTests.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import XCTest
@testable import TangemSdk

@MainActor
final class ResetCodesFlowTests: XCTestCase {
    func testIntroOpensFirstWithNewDesignAndIntro() {
        let presenter = ResetCodesPresenterMock()
        let controller = makeController(presenter: presenter, usesNewDesign: true, showsIntro: true)

        controller.start(codeType: .accessCode, cardId: nil) { _ in }

        XCTAssertEqual(presenter.stateNames, ["intro"])

        presenter.introRequest?.handle(.success(()))

        XCTAssertEqual(presenter.stateNames, ["intro", "requestCode"])
    }

    func testCodeRequestOpensFirstWithoutIntro() {
        let presenter = ResetCodesPresenterMock()
        let controller = makeController(presenter: presenter, usesNewDesign: true, showsIntro: false)

        controller.start(codeType: .accessCode, cardId: nil) { _ in }

        XCTAssertEqual(presenter.stateNames, ["requestCode"])
    }

    func testIntroNeedsNewDesign() {
        let presenter = ResetCodesPresenterMock()
        let controller = makeController(presenter: presenter, usesNewDesign: false, showsIntro: true)

        controller.start(codeType: .accessCode, cardId: nil) { _ in }

        XCTAssertEqual(presenter.stateNames, ["requestCode"])
    }

    func testClosingIntroCancelsFlow() {
        let presenter = ResetCodesPresenterMock()
        let controller = makeController(presenter: presenter, usesNewDesign: true, showsIntro: true)
        var result: Result<String, TangemSdkError>?

        controller.start(codeType: .accessCode, cardId: nil) { result = $0 }
        presenter.introRequest?.handle(.failure(.userCancelled))

        guard case .failure(.userCancelled) = result else {
            return XCTFail("Expected the flow to be cancelled, got \(String(describing: result))")
        }
        XCTAssertEqual(presenter.hideCount, 1)
    }

    func testFinishedShowsSuccessScreenWithNewDesign() throws {
        let presenter = ResetCodesPresenterMock()
        let service = ResetPinServiceMock()
        let controller = makeController(presenter: presenter, service: service, usesNewDesign: true, showsIntro: false)
        var result: Result<String, TangemSdkError>?

        controller.start(codeType: .accessCode, cardId: nil) { result = $0 }
        service.state.send(.finished)

        XCTAssertEqual(presenter.stateNames, ["requestCode", "success"])
        XCTAssertEqual(presenter.alertCount, 0)

        let request = try XCTUnwrap(presenter.successRequest)
        XCTAssertEqual(request.state, .finished)

        request.handle(.success(false))

        guard case .success = result else {
            return XCTFail("Expected the flow to finish, got \(String(describing: result))")
        }
    }

    func testFinishedLogsCompletionOnceWithNewDesign() async {
        let handler = AnalyticsHandlerMock()
        let presenter = ResetCodesPresenterMock()
        let service = ResetPinServiceMock()
        var config = Config()
        config.usesNewAccessCodeDesign = true
        config.analyticsHandler = handler
        let controller = ResetCodesController(resetService: service, viewDelegate: presenter, accessCodeFlow: AccessCodeFlow(config: config))

        controller.start(codeType: .accessCode, cardId: nil) { _ in }
        service.state.send(.finished)
        for _ in 0 ..< 100 {
            await Task.yield()
        }

        XCTAssertEqual(handler.events, [.resetCodesFinished])
    }

    func testUnpresentableIntroCancelsAndSuccessCompletes() {
        let viewDelegate = ResetCodesViewDelegate(style: TangemSdkStyle(), accessCodeFlow: AccessCodeFlow(config: Config()))
        let introCancelled = expectation(description: "intro cancelled")
        let successCompleted = expectation(description: "success completed")

        viewDelegate.setState(.intro(ResetCodesIntroRequest { result in
            if case .failure(.userCancelled) = result {
                introCancelled.fulfill()
            }
        }))
        wait(for: [introCancelled], timeout: 2)

        viewDelegate.setState(.success(ResetCodesRequest(type: .accessCode, state: .finished, cardId: nil) { result in
            if case .success(false) = result {
                successCompleted.fulfill()
            }
        }))
        wait(for: [successCompleted], timeout: 2)
    }

    func testIntroContinueAfterCloseIsIgnored() {
        let presenter = ResetCodesPresenterMock()
        let controller = makeController(presenter: presenter, usesNewDesign: true, showsIntro: true)

        controller.start(codeType: .accessCode, cardId: nil) { _ in }
        let request = presenter.introRequest
        request?.handle(.failure(.userCancelled))
        request?.handle(.success(()))

        XCTAssertEqual(presenter.stateNames, ["intro"])
        XCTAssertEqual(presenter.hideCount, 1)
    }

    func testFinishedShowsAlertWithoutNewDesign() {
        let presenter = ResetCodesPresenterMock()
        let service = ResetPinServiceMock()
        let controller = makeController(presenter: presenter, service: service, usesNewDesign: false, showsIntro: false)

        controller.start(codeType: .accessCode, cardId: nil) { _ in }
        service.state.send(.finished)

        XCTAssertEqual(presenter.stateNames, ["requestCode"])
        XCTAssertEqual(presenter.alertCount, 1)
    }

    func testCopyDropsDeviceNumberWhenCardIdIsEmpty() {
        let numbered = ResetCodesCopy(type: .accessCode, cardId: "•• 0000")
        let ring = ResetCodesCopy(type: .accessCode, cardId: "")

        XCTAssertTrue(numbered.stepTitle(for: .needScanResetCard).contains("••\u{00A0}0000"))
        XCTAssertTrue(numbered.successBody.contains("••\u{00A0}0000"))
        XCTAssertEqual(ring.stepTitle(for: .needScanResetCard), "reset_codes_prepare_device_title".localized)
        XCTAssertEqual(ring.stepTitle(for: .needWriteResetCard), "reset_codes_prepare_device_again_title".localized)
        XCTAssertEqual(ring.newCodeSubtitle, "reset_codes_new_code_subtitle".localized)
        XCTAssertEqual(ring.successBody, "reset_codes_success_body".localized)

        let unformatted = ResetCodesCopy(type: .accessCode, cardId: nil)
        XCTAssertEqual(unformatted.stepTitle(for: .needScanResetCard), "reset_codes_prepare_device_title".localized)
        XCTAssertEqual(unformatted.newCodeSubtitle, "reset_codes_new_code_subtitle".localized)
        XCTAssertEqual(unformatted.successBody, "reset_codes_success_body".localized)
    }

    func testNewDesignAccessCodeCopyNeverSaysReset() {
        let copies = [
            ResetCodesCopy(type: .accessCode, cardId: "•• 0000"),
            ResetCodesCopy(type: .accessCode, cardId: nil),
        ]
        let intro = [
            "reset_codes_intro_title",
            "reset_codes_intro_subtitle",
            "reset_codes_intro_backup_title",
            "reset_codes_intro_backup_subtitle",
            "reset_codes_intro_assets_title",
            "reset_codes_intro_assets_subtitle",
            "reset_codes_nfc_scan_device",
            "reset_codes_nfc_write_device",
            "common_finish",
        ].map { $0.localized }

        let texts = intro + copies.flatMap { copy in
            [copy.newCodeTitle, copy.newCodeSubtitle, copy.codePlaceholder, copy.confirmationPlaceholder, copy.successTitle, copy.successBody]
                + ResetPinService.State.allCases.flatMap { [copy.stepTitle(for: $0), copy.stepBody(for: $0)] }
        }

        for text in texts {
            XCTAssertFalse(text.localizedCaseInsensitiveContains("reset"), text)
            XCTAssertFalse(text.hasPrefix("reset_codes_"), "Missing string: \(text)")
        }
    }

    func testForgotButtonBeforeScanFollowsNewDesign() throws {
        XCTAssertTrue(try requestedCode(usesNewDesign: true, card: nil).showForgotButton)
        XCTAssertFalse(try requestedCode(usesNewDesign: false, card: nil).showForgotButton)
    }

    func testForgotButtonAfterScanFollowsCard() throws {
        let data = try Bundle.readFileAsData(name: "Card", in: .root)
        let card = try JSONDecoder.tangemSdkDecoder.decode(Card.self, from: data)

        XCTAssertFalse(card.canResetPin)
        XCTAssertFalse(try requestedCode(usesNewDesign: true, card: card).showForgotButton)

        var linkedCard = card
        linkedCard.backupStatus = .active(cardsCount: 2)

        XCTAssertTrue(linkedCard.canResetPin)
        XCTAssertTrue(try requestedCode(usesNewDesign: false, card: linkedCard).showForgotButton)
    }

    private func makeController(
        presenter: ResetCodesPresenterMock,
        service: ResetPinService = ResetPinServiceMock(),
        usesNewDesign: Bool,
        showsIntro: Bool
    ) -> ResetCodesController {
        var config = Config()
        config.usesNewAccessCodeDesign = usesNewDesign
        config.showsResetCodesIntro = showsIntro

        return ResetCodesController(
            resetService: service,
            viewDelegate: presenter,
            accessCodeFlow: AccessCodeFlow(config: config)
        )
    }

    private func requestedCode(usesNewDesign: Bool, card: Card?) throws -> UserCodeRequest {
        var config = Config()
        config.usesNewAccessCodeDesign = usesNewDesign
        var environment = SessionEnvironment(config: config)
        environment.card = card

        let viewDelegate = SessionViewDelegateMock()
        let session = CardSession(
            environment: environment,
            cardReader: CardReaderMock(),
            viewDelegate: viewDelegate,
            jsonConverter: nil,
            accessCodeRepository: nil,
            cardAccessTokensRepository: nil
        )

        session.requestUserCode(.accessCode, showWelcomeBackWarning: false) { _ in }

        return try XCTUnwrap(viewDelegate.codeRequest)
    }
}

@MainActor
private final class AnalyticsHandlerMock: TangemSdkAnalyticsHandler {
    private(set) var events: [TangemSdkAnalyticsEvent] = []

    func log(_ event: TangemSdkAnalyticsEvent) {
        events.append(event)
    }
}

private final class ResetPinServiceMock: ResetPinService {
    let state = CurrentValueSubject<State, Never>(.needCode)

    override var currentStatePublisher: AnyPublisher<State, Never> {
        state.eraseToAnyPublisher()
    }

    init() {
        super.init(config: Config())
    }
}

private final class ResetCodesPresenterMock: ResetCodesViewPresenting {
    private(set) var states: [ResetCodesViewState] = []
    private(set) var hideCount = 0
    private(set) var alertCount = 0

    var stateNames: [String] {
        states.map { state in
            switch state {
            case .empty: return "empty"
            case .intro: return "intro"
            case .requestCode: return "requestCode"
            case .resetCodes: return "resetCodes"
            case .success: return "success"
            }
        }
    }

    var introRequest: ResetCodesIntroRequest? {
        states.lazy.compactMap { state -> ResetCodesIntroRequest? in
            if case .intro(let request) = state { return request }
            return nil
        }.last
    }

    var successRequest: ResetCodesRequest? {
        states.lazy.compactMap { state -> ResetCodesRequest? in
            if case .success(let request) = state { return request }
            return nil
        }.last
    }

    func setState(_ state: ResetCodesViewState) {
        states.append(state)
    }

    func hide(completion: (() -> Void)?) {
        hideCount += 1
        completion?()
    }

    func showError(_ error: TangemSdkError) {}

    func showAlert(_ title: String, message: String, onContinue: @escaping () -> Void) {
        alertCount += 1
    }
}

private final class SessionViewDelegateMock: SessionViewDelegate {
    private(set) var codeRequest: UserCodeRequest?

    func showAlertMessage(_ text: String) {}
    func tagConnected() {}
    func tagLost(message: String) {}
    func wrongCard(message: String) {}
    func sessionStarted() {}
    func sessionStopped(completion: (() -> Void)?) { completion?() }
    func attestationDidFailDevCard(onContinue: @escaping () -> Void, onCancel: @escaping () -> Void) {}
    func attestationCompletedWithWarnings(onContinue: @escaping () -> Void) {}
    func attestationCompletedOffline(onContinue: @escaping () -> Void, onCancel: @escaping () -> Void, onRetry: @escaping () -> Void) {}
    func showHealthAlert(onContinue: @escaping () -> Void) {}

    func setState(_ state: SessionViewState) {
        if case .requestCode(let request) = state {
            codeRequest = request
        }
    }
}

private final class CardReaderMock: CardReader {
    var isPaused: Bool = false
    var isReady: Bool = true
    var alertMessage: String = ""
    let tag = CurrentValueSubject<NFCTagType, TangemSdkError>(.none)
    let viewEventsPublisher = CurrentValueSubject<CardReaderViewEvent, Never>(.none)

    func startSession(with message: String) {}
    func resumeSession() {}
    func stopSession(with errorMessage: String?) {}
    func pauseSession(with errorMessage: String?) {}
    func stopSession(with error: Error) {}
    func restartPolling(silent: Bool) {}

    func sendPublisher(apdu: CommandApdu, retryOnFail: Bool) -> AnyPublisher<ResponseApdu, TangemSdkError> {
        Empty().eraseToAnyPublisher()
    }
}
