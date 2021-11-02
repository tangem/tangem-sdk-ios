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
    @Published public private(set) var currentState: State = .needCode
    @Published public private(set) var error: TangemSdkError? = nil
    
    public var resetPinCardId: String? { repo.resetPinCard?.cardId }
    
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
        repo.accessCode = nil
        
        if handleErrors {
            guard !code.isEmpty else {
                throw TangemSdkError.accessCodeRequired
            }
            
            if code == UserCodeType.accessCode.defaultValue {
                throw TangemSdkError.accessCodeCannotBeChanged
            }
        }
        
        repo.accessCode = code.sha256()
        currentState = currentState.next()
    }
    
    public func setPasscode(_ code: String) throws {
        repo.passcode = nil
        
        if handleErrors {
            guard !code.isEmpty else {
                throw TangemSdkError.passcodeRequired
            }
            
            if code == UserCodeType.passcode.defaultValue {
                throw TangemSdkError.passcodeCannotBeChanged
            }
        }
        repo.passcode = code.sha256()
        currentState = currentState.next()
    }
    
    public func proceed() {
        switch currentState {
        case .needScanResetCard:
            scanResetPinCard(handleCompletion)
        case .needScanConfirmationCard:
            scanConfirmationCard(handleCompletion)
        case .needWriteResetCard:
            writeResetPinCard(handleCompletion)
        case .finished, .needCode:
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
        
        var accessCode = repo.accessCode
        var passcode = repo.passcode
        
        if handleErrors {
            if !resetPinCard.isAccessCodeSet {
                accessCode = UserCodeType.accessCode.defaultValue.sha256()
            }
            
            if !resetPinCard.isPasscodeSet {
                passcode = UserCodeType.passcode.defaultValue.sha256()
            }
        }
        
        guard let accessCodeUnwrapped = accessCode else {
            completion(.failure(.accessCodeRequired))
            return
        }
        
        guard let passcodeUnwrapped = passcode else {
            completion(.failure(.passcodeRequired))
            return
        }
        
        let task = ResetPinTask(confirmationCard: confirmationCard, accessCode: accessCodeUnwrapped, passcode: passcodeUnwrapped)
        
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
        case needCode
        case needScanResetCard
        case needScanConfirmationCard
        case needWriteResetCard
        case finished
        
        var messageTitle: String {
            switch self {
            case .finished: return "common_success".localized
            case .needScanConfirmationCard:
                return "reset_codes_message_title_backup".localized
            case .needScanResetCard, .needWriteResetCard:
                return "reset_codes_message_title_restore".localized
            case .needCode:
                return ""
            }
        }
        
        var messageBody: String {
            switch self {
            case .finished: return "reset_codes_success_message".localized
            case .needScanConfirmationCard:
                return "reset_codes_message_body_backup".localized
            case .needScanResetCard:
                return "reset_codes_message_body_restore".localized
            case .needWriteResetCard:
                return "reset_codes_message_body_restore_final".localized
            case .needCode:
                return ""
            }
        }
        
        var cardType: CardType {
            switch self {
            case .needCode, .needScanResetCard, .needWriteResetCard, .finished:
                return .origin
            case .needScanConfirmationCard:
                return .backup
            }
        }
    }
}

enum CardType {
    case origin
    case backup
    
    var topIndex: Int {
        switch self {
        case .origin:
            return 0
        case .backup:
            return 1
        }
    }
    
    var bottomIndex: Int {
        switch self {
        case .origin:
            return 1
        case .backup:
            return 0
        }
    }
}

struct ResetPinCard {
    let cardId: String
    let backupKey: Data
    let attestSignature: Data
    let token: Data
    let isAccessCodeSet: Bool
    let isPasscodeSet: Bool
}

struct ConfirmationCard {
    let cardId: String
    let backupKey: Data
    let salt: Data
    let authorizeSignature: Data
}

