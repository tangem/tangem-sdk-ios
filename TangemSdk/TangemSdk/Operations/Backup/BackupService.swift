//
//  BackupService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 25.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13.0, *)
public class BackupService: ObservableObject {
    public static let maxBackupCardsCount = 2
    
    @Published public private(set) var currentState: State = .preparing
    
    public var canAddBackupCards: Bool {
        addedBackupCardsCount < BackupService.maxBackupCardsCount
        &&  repo.originCard?.linkingKey != nil
    }
    
    public var addedBackupCardsCount: Int { repo.backupCards.count }
    public var canProceed: Bool { currentState != .preparing && currentState != .finished }
    public var accessCodeIsSet: Bool { repo.accessCode != nil }
    public var passcodeIsSet: Bool { repo.passcode != nil }
    public var originCardIsSet: Bool { repo.originCard != nil }
    
    private let sdk: TangemSdk
    private var repo: BackupRepo = .init()
    
    private var handleErrors: Bool { sdk.config.handleErrors }
    
    public init(sdk: TangemSdk) {
        self.sdk = sdk
    }
    
    deinit {
        Log.debug("BackupService deinit")
    }
    
    public func addBackupCard(completion: @escaping CompletionResult<Void>) {
        guard let originCardLinkingKey = repo.originCard?.linkingKey else {
            completion(.failure(.missingOriginCard))
            return
        }
        
        if handleErrors {
            guard addedBackupCardsCount < BackupService.maxBackupCardsCount else {
                completion(.failure(.tooMuchBackupCards))
                return
            }
        }
        
        readBackupCard(originCardLinkingKey, completion: completion)
    }
    
    public func setAccessCode(_ code: String) throws {
        repo.accessCode = nil
        
        if handleErrors {
            guard !code.isEmpty else {
                throw TangemSdkError.invalidParams
            }
            
            if code == UserCodeType.accessCode.defaultValue {
                throw TangemSdkError.accessCodeCannotBeChanged
            }
        }
        
        guard currentState == .preparing || currentState == .needWriteOriginCard else {
            throw TangemSdkError.accessCodeCannotBeChanged
        }
        
        repo.accessCode = code.sha256()
        updateState()
    }
    
    public func setPasscode(_ code: String) throws {
        repo.passcode = nil
        
        if handleErrors {
            guard !code.isEmpty else {
                throw TangemSdkError.invalidParams
            }
            
            if code == UserCodeType.passcode.defaultValue {
                throw TangemSdkError.passcodeCannotBeChanged
            }
        }
        
        guard currentState == .preparing || currentState == .needWriteOriginCard else {
            throw TangemSdkError.passcodeCannotBeChanged
        }
        
        repo.passcode = code.sha256()
        updateState()
    }
    
    public func proceedBackup(completion: @escaping CompletionResult<State>) {
        switch currentState {
        case .needWriteOriginCard:
            handleWriteOriginCard() {
                self.handleCompletion($0, completion: completion)
            }
        case .needWriteBackupCard(let index):
            handleWriteBackupCard(index: index) {
                self.handleCompletion($0, completion: completion)
            }
        case .finished:
            completion(.success(.finished))
        case .preparing:
            completion(.failure(TangemSdkError.backupInvalidCommandSequence))
        }
    }
    
    public func setOriginCard(_ originCard: OriginCard) {
        repo.originCard = originCard
        updateState()
        
        DispatchQueue.global().async {
            self.fetchCertificate(for: originCard.cardId, cardPublicKey: originCard.cardPublicKey)
        }
    }
    
    public func readOriginCard(completion: @escaping CompletionResult<Void>) {
        sdk.startSession(with: StartOriginCardLinkingCommand(),
                         initialMessage: Message(header: "Scan origin card")
        ) {[weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.setOriginCard(response)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func handleCompletion(_ result: Result<Void, TangemSdkError>, completion: @escaping CompletionResult<State>) -> Void {
        switch result {
        case .success:
            completion(.success(updateState()))
        case .failure(let error):
            completion(.failure(error.toTangemSdkError()))
        }
    }
    
    @discardableResult
    private func updateState() -> State {
        if repo.accessCode == nil
            || repo.originCard == nil
            || repo.backupCards.isEmpty {
            currentState = .preparing
        } else if repo.attestSignature == nil || repo.backupData.isEmpty {
            currentState = .needWriteOriginCard
        } else if repo.finalizedBackupCardsCount < repo.backupCards.count {
            currentState = .needWriteBackupCard(index: repo.finalizedBackupCardsCount + 1)
        } else {
            currentState = .finished
        }
        
        return currentState
    }
    
    private func addBackupCard(_ backupCard: BackupCard) {
        if let existingIndex = repo.backupCards.firstIndex(where: { $0.cardId == backupCard.cardId }) {
            repo.backupCards.remove(at: existingIndex)
        }
        
        repo.backupCards.append(backupCard)
        updateState()
        
        DispatchQueue.global().async {
            self.fetchCertificate(for: backupCard.cardId, cardPublicKey: backupCard.cardPublicKey)
        }
    }
    
    private func readBackupCard(_ originCardLinkingKey: Data, completion: @escaping CompletionResult<Void>) {
        sdk.startSession(with: StartBackupCardLinkingTask(originCardLinkingKey: originCardLinkingKey,
                                                          addedBackupCards: repo.backupCards.map { $0.cardId }),
                         initialMessage: Message(header: "Scan backup card with index: \(repo.backupCards.count + 1)")) {[weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.addBackupCard(response)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func handleWriteOriginCard(completion: @escaping CompletionResult<Void>) {
        do {
            if handleErrors {
                if repo.accessCode == nil && repo.passcode == nil {
                    throw TangemSdkError.accessCodeOrPasscodeRequired
                }
            }
            
            let accessCode = repo.accessCode ?? UserCodeType.accessCode.defaultValue.sha256()
            let passcode = repo.passcode ?? UserCodeType.passcode.defaultValue.sha256()
            
            guard let originCard = repo.originCard else {
                throw TangemSdkError.missingOriginCard
            }
            
            let linkableBackupCards: [LinkableBackupCard] = try repo.backupCards.map { card -> LinkableBackupCard in
                guard let certificate = repo.certificates[card.cardId] else {
                    throw TangemSdkError.certificateRequired
                }
                
                return card.makeLinkable(with: certificate)
            }
            
            if handleErrors {
                guard !linkableBackupCards.isEmpty else {
                    throw TangemSdkError.backupCardRequired
                }
                
                guard linkableBackupCards.count < 3 else {
                    throw TangemSdkError.tooMuchBackupCards
                }
            }
            
            let task = FinalizeOriginCardTask(backupCards: linkableBackupCards,
                                              accessCode: accessCode,
                                              passcode: passcode,
                                              originCardLinkingKey: originCard.linkingKey,
                                              readBackupStartIndex: repo.backupData.count,
                                              attestSignature: repo.attestSignature,
                                              onLink: { self.repo.attestSignature = $0 },
                                              onRead: { self.repo.backupData[$0.0] = $0.1 })
            
            sdk.startSession(with: task, cardId: originCard.cardId,
                             initialMessage: Message(header: "Scan origin card with cardId: \(CardIdFormatter().string(from: originCard.cardId))"),
                             completion: completion)
            
        } catch {
            completion(.failure(error.toTangemSdkError()))
        }
    }
    
    private func handleWriteBackupCard(index: Int, completion: @escaping CompletionResult<Void>) {
        do {
            if handleErrors {
                if repo.accessCode == nil && repo.passcode == nil {
                    throw TangemSdkError.accessCodeOrPasscodeRequired
                }
            }
            
            let accessCode = repo.accessCode ?? UserCodeType.accessCode.defaultValue.sha256()
            let passcode = repo.passcode ?? UserCodeType.passcode.defaultValue.sha256()
            
            guard let attestSignature = repo.attestSignature else {
                throw TangemSdkError.originCardRequired
            }
            
            guard let originCard = repo.originCard else {
                throw TangemSdkError.missingOriginCard
            }
            
            guard let originCardCertificate = repo.certificates[originCard.cardId] else {
                throw TangemSdkError.certificateRequired
            }
            
            let cardIndex = index - 1
            
            guard cardIndex < repo.backupCards.count else {
                throw TangemSdkError.backupCardRequired
            }
            
            guard !repo.backupCards.isEmpty else {
                throw TangemSdkError.backupCardRequired
            }
            
            if handleErrors {
                guard repo.backupCards.count < 3 else {
                    throw TangemSdkError.tooMuchBackupCards
                }
            }
            
            let backupCard = repo.backupCards[cardIndex]
            
            guard let backupData = repo.backupData[backupCard.cardId] else {
                throw TangemSdkError.backupInvalidCommandSequence
            }
            
            let command = FinalizeBackupCardTask(originCard: originCard.makeLinkable(with: originCardCertificate),
                                                 backupCards: repo.backupCards,
                                                 backupData: backupData,
                                                 attestSignature: attestSignature,
                                                 accessCode: accessCode,
                                                 passcode: passcode)
            
            sdk.startSession(with: command, cardId: backupCard.cardId,
                             initialMessage: Message(header: "Scan backup card with cardId: \(CardIdFormatter().string(from: backupCard.cardId))")) { result in
                switch result {
                case .success:
                    self.repo.finalizedBackupCardsCount += 1
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            
        } catch {
            completion(.failure(error.toTangemSdkError()))
        }
    }
    
    private func fetchCertificate(for cardId: String, cardPublicKey: Data) {
        //todo: fetch from backend
        
        let issuerPrivateKey = Data(hexString: "11121314151617184771ED81F2BACF57479E4735EB1405083927372D40DA9E92")
        let signature = cardPublicKey.sign(privateKey: issuerPrivateKey)!
        let certificate = try! TlvBuilder()
            .append(.cardPublicKey, value: cardPublicKey)
            .append(.issuerDataSignature, value: signature)
            .serialize()
        
        repo.certificates[cardId] = certificate
    }
}

@available(iOS 13.0, *)
extension BackupService {
    class BackupRepo {
        var accessCode: Data? = nil
        var passcode: Data? = nil
        var originCard: OriginCard? = nil
        var attestSignature: Data? = nil
        var backupCards: [BackupCard] = []
        var certificates: [String:Data] = [:]
        var backupData: [String:EncryptedBackupData] = [:]
        var finalizedBackupCardsCount: Int = 0
    }
    
    public enum State: Equatable {
        case preparing
        case needWriteOriginCard
        case needWriteBackupCard(index: Int)
        case finished
    }
}

public struct OriginCard {
    public let cardId: String
    public let cardPublicKey: Data
    public let linkingKey: Data
    
    func makeLinkable(with certificate: Data) -> LinkableOriginCard {
        LinkableOriginCard(cardId: cardId,
                           cardPublicKey: cardPublicKey,
                           linkingKey: linkingKey,
                           certificate: certificate)
    }
}

struct LinkableOriginCard {
    let cardId: String
    let cardPublicKey: Data
    let linkingKey: Data
    let certificate: Data
}

struct BackupCard {
    let cardId: String
    let cardPublicKey: Data
    let linkingKey: Data
    let attestSignature: Data
    
    func makeLinkable(with certificate: Data) -> LinkableBackupCard {
        LinkableBackupCard(cardId: cardId,
                           cardPublicKey: cardPublicKey,
                           linkingKey: linkingKey,
                           attestSignature: attestSignature,
                           certificate: certificate)
    }
}

struct EncryptedBackupData {
    let data: Data
    let salt: Data
}

struct LinkableBackupCard {
    let cardId: String
    let cardPublicKey: Data
    let linkingKey: Data
    let attestSignature: Data
    let certificate: Data
}
