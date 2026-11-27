//
//  ResetCodesController.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public class ResetCodesController {
    public var cardIdDisplayFormat: CardIdDisplayFormat = .full

    private let resetService: ResetPinService
    private let viewDelegate: ResetCodesViewPresenting
    private let accessCodeFlow: AccessCodeFlow

    private var bag = Set<AnyCancellable>()
    private var codeType: UserCodeType?
    private var completion: CompletionResult<String>?
    private var newCode: String = ""
    private var cardId: String?

    private var formattedCardId: String? {
        cardId.flatMap { CardIdFormatter(style: cardIdDisplayFormat).string(from: $0) }
    }

    init(resetService: ResetPinService, viewDelegate: ResetCodesViewPresenting, accessCodeFlow: AccessCodeFlow) {
        self.resetService = resetService
        self.viewDelegate = viewDelegate
        self.accessCodeFlow = accessCodeFlow
        bind()
    }

    deinit {
        Log.debug("ResetCodesController deinit")
    }

    public func start(codeType: UserCodeType, cardId: String?, completion: @escaping CompletionResult<String>) {
        self.cardId = cardId
        self.codeType = codeType
        self.completion = completion

        if accessCodeFlow.showsResetCodesIntro {
            let request = ResetCodesIntroRequest { [weak self] result in
                self?.handleIntro(result)
            }
            viewDelegate.setState(.intro(request))
        } else {
            requestCode(codeType)
        }
    }

    private func requestCode(_ codeType: UserCodeType) {
        // The flow retries after recoverable errors (rejected code, failed scan),
        // so the prompt must stay invokable
        let request = UserCodeRequest(type: codeType, cardId: formattedCardId, isOneShot: false) { [weak self] result in
            self?.handleCodeInput(result)
        }
        viewDelegate.setState(.requestCode(request))
    }

    private func bind() {
        resetService
            .currentStatePublisher
            .dropFirst()
            .sink { [weak self] newState in
                guard let self else { return }

                switch newState {
                case .finished where accessCodeFlow.usesNewDesign:
                    accessCodeFlow.log(.resetCodesFinished)
                    if let request = makeRequest(for: newState) {
                        viewDelegate.setState(.success(request))
                    }
                case .finished:
                    accessCodeFlow.log(.screenOpened(newState.analyticsScreen), .resetCodesFinished)
                    viewDelegate.showAlert(
                        newState.messageTitle,
                        message: newState.messageBody,
                        onContinue: { [weak self] in
                            self?.accessCodeFlow.log(.buttonTapped(.finish, screen: newState.analyticsScreen))
                            self?.handleContinue(.success(false))
                        }
                    )
                default:
                    if let request = makeRequest(for: newState) {
                        viewDelegate.setState(.resetCodes(request))
                    }
                }
            }
            .store(in: &bag)

        resetService
            .errorPublisher
            .compactMap { $0 }
            .sink { [accessCodeFlow] error in
                accessCodeFlow.logFailure(error)
            }
            .store(in: &bag)
    }

    private func makeRequest(for state: ResetPinService.State) -> ResetCodesRequest? {
        guard let codeType else { return nil }

        return ResetCodesRequest(type: codeType, state: state, cardId: formattedCardId) { [weak self] result in
            self?.handleContinue(result)
        }
    }

    private func handleIntro(_ result: Result<Void, TangemSdkError>) {
        guard completion != nil else { return }

        switch result {
        case .success:
            if let codeType {
                requestCode(codeType)
            }
        case .failure(let error):
            finish(with: .failure(error))
        }
    }

    private func handleCodeInput(_ result: Result<String, TangemSdkError>) {
        switch result {
        case .success(let code):
            do {
                try resetService.setAccessCode(code)
                newCode = code
            } catch {
                viewDelegate.showError(error.toTangemSdkError())
            }
        case .failure(let error):
            finish(with: .failure(error))
        }
    }

    private func handleContinue(_ result: Result<Bool, TangemSdkError>) {
        switch result {
        case .success(let shouldContinue):
            if shouldContinue {
                resetService.proceed(with: cardId)
            } else { // completed
                finish(with: .success(newCode))
            }
        case .failure(let error):
            finish(with: .failure(error))
        }
    }

    private func finish(with result: Result<String, TangemSdkError>) {
        guard let completion else { return }

        self.completion = nil
        viewDelegate.hide {
            completion(result)
        }
    }
}
