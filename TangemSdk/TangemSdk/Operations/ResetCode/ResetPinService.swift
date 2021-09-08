//
//  ResetPinService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public class ResetPinService: ObservableObject {
    @Published public private(set) var currentState: State = .needScanResetCard
    @Published public private(set) var error: TangemSdkError? = nil
    
    private let sdk: TangemSdk
    private var repo: ResetPinRepo = .init()
    private var handleErrors: Bool { sdk.config.handleErrors }
    
    public init(sdk: TangemSdk) {
        self.sdk = sdk
    }
    
    deinit {
        Log.debug("ResetPinService deinit")
    }
    
    public func setAccessCode(_ code: String) throws {
        if handleErrors {
            guard !code.isEmpty else {
                throw TangemSdkError.invalidParams
            }
            
            if code == UserCodeType.accessCode.defaultValue {
                throw TangemSdkError.invalidParams
            }
        }
        
        repo.accessCode = code.sha256()
    }
    
    public func setPasscode(_ code: String) throws {
        if handleErrors {
            guard !code.isEmpty else {
                throw TangemSdkError.invalidParams
            }
            
            if code == UserCodeType.passcode.defaultValue {
                throw TangemSdkError.invalidParams
            }
        }
        repo.passcode = code.sha256()
    }
    
    public func proceed() {
        switch currentState {
        case .needScanResetCard:
            scanResetPinCard(handleCompletion)
        case .needScanConfirmationCard:
            scanConfirmationCard(handleCompletion)
        case .needWriteResetCard:
            writeResetPinCard(handleCompletion)
        case .finished:
            break
        }
    }
    
    private func handleCompletion(_ result: Result<Void, TangemSdkError>) -> Void {
        switch result {
        case .success:
            currentState = currentState.next()
        case .failure(let error):
            self.error = error
        }
    }
    
    private func scanResetPinCard(_ completion: @escaping CompletionResult<Void>) {
        let command = GetResetPinTokenCommand()
        sdk.startSession(with: command,
                         initialMessage: Message(header: "Scan the card on which you want to reset the pin")) { result in
            switch result {
            case .success(let response):
                self.repo.resetPinCard = response
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func scanConfirmationCard(_ completion: @escaping CompletionResult<Void>) {
        guard let resetPinCard = repo.resetPinCard else {
            completion(.failure(.unknownError))
            return
        }
        
        let command = SignResetPinTokenCommand(resetPinCard: resetPinCard)
        sdk.startSession(with: command,
                         initialMessage: Message(header: "Scan the confirmation card")) { result in
            switch result {
            case .success(let response):
                self.repo.confirmationCard = response
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func writeResetPinCard(_ completion: @escaping CompletionResult<Void>) {
        guard let resetPinCard = repo.resetPinCard else {
            completion(.failure(.unknownError))
            return
        }
        
        guard let confirmationCard = repo.confirmationCard else {
            completion(.failure(.unknownError))
            return
        }
        
        guard let accessCode = repo.accessCode else {
            completion(.failure(.accessCodeRequired))
            return
        }
        
        guard let passcode = repo.passcode else {
            completion(.failure(.passcodeRequired))
            return
        }
        
        let task = ResetPinTask(confirmationCard: confirmationCard, accessCode: accessCode, passcode: passcode)
        
        sdk.startSession(with: task,
                         cardId: resetPinCard.cardId,
                         initialMessage: Message(header: "Scan card to reset user codes")) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

@available(iOS 13.0, *)
extension ResetPinService {
    class ResetPinRepo {
        var confirmationCard: ConfirmationCard? = nil
        var resetPinCard: ResetPinCard? = nil
        var accessCode: Data?
        var passcode: Data?
    }
    
    public enum State: Equatable, CaseIterable {
        case needScanResetCard
        case needScanConfirmationCard
        case needWriteResetCard
        case finished
    }
}

struct ResetPinCard {
    let cardId: String
    let backupKey: Data
    let attestSignature: Data
    let token: Data
}

struct ConfirmationCard {
    let cardId: String
    let backupKey: Data
    let salt: Data
    let authorizeSignature: Data
}

