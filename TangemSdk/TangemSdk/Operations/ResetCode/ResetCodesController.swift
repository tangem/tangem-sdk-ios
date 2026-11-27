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
    private let viewDelegate: ResetCodesViewDelegate
    private let accessCodeFlow: AccessCodeFlow

    private var bag = Set<AnyCancellable>()
    private var codeType: UserCodeType?
    private var completion: CompletionResult<String>?
    private var newCode: String = ""
    private var cardId: String?

    private var formattedCardId: String? {
        cardId.flatMap { CardIdFormatter(style: cardIdDisplayFormat).string(from: $0) }
    }

    init(resetService: ResetPinService, viewDelegate: ResetCodesViewDelegate, accessCodeFlow: AccessCodeFlow) {
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
                    if let codeType = codeType {
                        let request = ResetCodesRequest(
                            type: codeType,
                            state: newState,
                            cardId: formattedCardId
                        ) { [weak self] result in
                            self?.handleContinue(result)
                        }
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
