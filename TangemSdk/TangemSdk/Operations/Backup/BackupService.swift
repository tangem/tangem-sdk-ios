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
    private let sdk: TangemSdk
    private var repo: BackupRepo = .init()
    
    @Published public private(set) var currentState: BackupServiceState = .needBackupCardsCount
    
    public init(sdk: TangemSdk, backupCardsCount: Int? = nil, accessCode: String? = nil) throws {
        self.sdk = sdk
        
        if let backupCardsCount = backupCardsCount {
            try self.handleBackupCount(.backupCardsCount(backupCardsCount))
            nextState()
        }
        
        if let accessCode = accessCode {
            try self.handleAccessCode(.accessCode(accessCode))
            nextState()
        }
    }
    
    deinit {
        Log.debug("BackupService deinit")
    }
    
    public func continueProcess(with params: StateParams = .empty, completion: @escaping CompletionResult<BackupServiceState>) {
        do {
            switch currentState {
            case .needBackupCardsCount:
                try handleBackupCount(params)
                completion(.success(nextState()))
            case .needAccessCode:
                try handleAccessCode(params)
                completion(.success(nextState()))
            case .needScanOriginCard:
                handleReadOriginCard() {
                    self.handleCompletion($0, completion: completion)
                }
            case .needScanBackupCard(let index):
                handleReadBackupCard(index: index) {
                    self.handleCompletion($0, completion: completion)
                }
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
            }
        }
        catch {
            completion(.failure(error.toTangemSdkError()))
        }
    }
    
    private func handleCompletion(_ result: Result<Void, TangemSdkError>, completion: @escaping CompletionResult<BackupServiceState>) -> Void {
        switch result {
        case .success:
            completion(.success(nextState()))
        case .failure(let error):
            completion(.failure(error.toTangemSdkError()))
        }
    }
    
    @discardableResult
    private func nextState() -> BackupServiceState {
        switch currentState {
        case .needBackupCardsCount:
            currentState = .needAccessCode //todo check if access code already exists
        case .needAccessCode:
            currentState = .needScanOriginCard
        case .needScanOriginCard:
            currentState = .needScanBackupCard(index: 1)
        case .needScanBackupCard(let index):
            if index == repo.backupCardsCount {
                currentState = .needWriteOriginCard
            } else {
                currentState = .needScanBackupCard(index: index + 1)
            }
        case .needWriteOriginCard:
            currentState = .needWriteBackupCard(index: 1)
        case .needWriteBackupCard(let index):
            if index == repo.backupCardsCount {
                currentState = .finished
            } else {
                currentState = .needWriteBackupCard(index: index + 1)
            }
        case .finished:
            break
        }
        
        return currentState
    }
    
    private func handleBackupCount(_ params: StateParams) throws {
        guard case let .backupCardsCount(count) = params else {
            throw TangemSdkError.invalidParams
        }
        
        guard count > 0 && count < 3 else {
            throw TangemSdkError.invalidParams
        }
        
        repo.backupCardsCount = count
    }
    
    private func handleAccessCode(_ params: StateParams) throws {
        guard case let .accessCode(code) = params else {
            throw TangemSdkError.invalidParams
        }
        
        guard !code.isEmpty else {
            throw TangemSdkError.invalidParams
        }
        
        repo.accessCode = code.sha256()
    }
    
    private func handleReadOriginCard(completion: @escaping CompletionResult<Void>) {
        sdk.startSession(with: StartOriginCardLinkingCommand(),
                         initialMessage: Message(header: "Scan origin card")
        ) {[weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.repo.originCard = OriginCard(cardId: response.cardId,
                                                  cardPublicKey: response.cardPublicKey,
                                                  linkingKey: response.linkingKey)
                DispatchQueue.global().async {
                    self.fetchCertificate(for: response.cardId, cardPublicKey: response.cardPublicKey)
                }
                
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func handleReadBackupCard(index: Int, completion: @escaping CompletionResult<Void>) {
        guard let originCardLinkingKey = repo.originCard?.linkingKey else {
            completion(.failure(.missingOriginCard))
            return
        }
        
        sdk.startSession(with: StartBackupCardLinkingCommand(originCardLinkingKey: originCardLinkingKey),
                         initialMessage: Message(header: "Scan backup card with index: \(index)")) {[weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                let backupCard = BackupCard(cardId: response.cardId,
                                            cardPublicKey: response.cardPublicKey,
                                            linkingKey: response.linkingKey,
                                            attestSignature: response.attestSignature)
                
                self.repo.backupCards.append(backupCard)
                
                DispatchQueue.global().async {
                    self.fetchCertificate(for: response.cardId, cardPublicKey: response.cardPublicKey)
                }
                
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func handleWriteOriginCard(completion: @escaping CompletionResult<Void>) {
        do {
            guard let accessCode = repo.accessCode else {
                throw TangemSdkError.accessCodeRequired
            }
            
            guard let passcode = repo.passcode else {
                throw TangemSdkError.passcodeRequired
            }
            
            guard let originCard = repo.originCard else {
                throw TangemSdkError.missingOriginCard
            }
            
            let linkableBackupCards: [LinkableBackupCard] = try repo.backupCards.map { card -> LinkableBackupCard in
                guard let certificate = repo.certificates[card.cardId] else {
                    throw TangemSdkError.certificateRequired
                }
                
                return card.makeLinkable(with: certificate)
            }
            
            guard !linkableBackupCards.isEmpty else {
                throw TangemSdkError.backupCardRequired
            }
            
            guard linkableBackupCards.count < 3 else {
                throw TangemSdkError.tooMuchBackupCards
            }
            
            let task = FinalizeOriginCardTask(backupCards: linkableBackupCards,
                                              accessCode: accessCode,
                                              passcode: passcode,
                                              originCardLinkingKey: originCard.linkingKey,
                                              attestSignature: repo.attestSignature,
                                              onLink: { self.repo.attestSignature = $0 })
            
            sdk.startSession(with: task, cardId: originCard.cardId,
                             initialMessage: Message(header: "Scan origin card with cardId: \(originCard.cardId)")) {[weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let response):
                    self.repo.backupData = response.backupData
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            
        } catch {
            completion(.failure(error.toTangemSdkError()))
        }
    }
    
    private func handleWriteBackupCard(index: Int, completion: @escaping CompletionResult<Void>) {
        do {
            guard let accessCode = repo.accessCode else {
                throw TangemSdkError.accessCodeRequired
            }
            
            guard let passcode = repo.passcode else {
                throw TangemSdkError.passcodeRequired
            }
            
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
            
            guard repo.backupCards.count < 3 else {
                throw TangemSdkError.tooMuchBackupCards
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
                             initialMessage: Message(header: "Scan backup card with cardId: \(originCard.cardId)")) { result in
                switch result {
                case .success:
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
class BackupRepo {
    var backupCardsCount: Int? = nil
    var accessCode: Data? = nil
    var passcode: Data? = UserCodeType.passcode.defaultValue.sha256()
    var originCard: OriginCard? = nil
    var attestSignature: Data? = nil
    var backupCards: [BackupCard] = []
    var certificates: [String:Data] = [:]
    var backupData: [String:EncryptedBackupData] = [:]
}

struct OriginCard {
    let cardId: String
    let cardPublicKey: Data
    let linkingKey: Data
    
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

public enum StateParams {
    case empty
    case accessCode(String)
    case backupCardsCount(Int)
}

public enum BackupServiceState {
    case needBackupCardsCount
    case needAccessCode
    case needScanOriginCard
    case needScanBackupCard(index: Int)
    case needWriteOriginCard
    case needWriteBackupCard(index: Int)
    case finished
}
