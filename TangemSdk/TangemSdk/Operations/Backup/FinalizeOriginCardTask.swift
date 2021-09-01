//
//  ReadFullBackupData.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
struct FinalizeOriginCardResponse {
    let backupData: [String:EncryptedBackupData]
}

@available(iOS 13.0, *)
class FinalizeOriginCardTask: CardSessionRunnable {
    private let backupCards: [LinkableBackupCard]
    private let accessCode: Data
    private let passcode: Data
    private let originCardLinkingKey: Data //only for verification
    private var attestSignature: Data? //We already have attestSignature
    private let onLink: (Data) -> Void
    
    private var backupData: [String:EncryptedBackupData] = [:]
  
    init(backupCards: [LinkableBackupCard],
         accessCode: Data,
         passcode: Data,
         originCardLinkingKey: Data,
         attestSignature: Data?,
         onLink: @escaping (Data) -> Void) {
        self.backupCards = backupCards
        self.accessCode = accessCode
        self.passcode = passcode
        self.originCardLinkingKey = originCardLinkingKey
        self.attestSignature = attestSignature
        self.onLink = onLink
    }
    
    deinit {
        Log.debug("FinalizeOriginCardTask deinit")
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<FinalizeOriginCardResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        guard let backupStatus = card.backupStatus else {
            completion(.failure(.notSupportedFirmwareVersion))
            return
        }
        
        let linkAction = getLinkAction(with: backupStatus)
        
    
        var accessCodeCopy: UserCode? = nil
        var passcodeCopy: UserCode? = nil
        
        if case .retry = linkAction { //User codes already changed. We should swap codes
            accessCodeCopy = session.environment.accessCode
            passcodeCopy = session.environment.accessCode
        
            session.environment.accessCode = UserCode(.accessCode, value: accessCode)
            session.environment.passcode = UserCode(.passcode, value: passcode)
        }
        
        if linkAction != .skip {
            let command = LinkBackupCardsCommand(backupCards: backupCards,
                         accessCode: accessCode,
                         passcode: passcode,
                         originCardLinkingKey: originCardLinkingKey)
            
            command.run(in: session) { linkResult in
                if case .retry = linkAction { // Swap codes back
                    session.environment.accessCode = accessCodeCopy!
                    session.environment.passcode = passcodeCopy!
                }
            
                switch linkResult {
                case .success(let linkResponse):
                    self.onLink(linkResponse.attestSignature)
                    self.readBackupData(session: session, index: 0, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            self.readBackupData(session: session, index: 0, completion: completion)
        }
    }

    private func readBackupData(session: CardSession, index: Int, completion: @escaping CompletionResult<FinalizeOriginCardResponse>) {
        if index >= backupCards.count {
            completion(.success(FinalizeOriginCardResponse(backupData: backupData)))
            return
        }
        
        let currentBackupCard = backupCards[index]
        let command = ReadBackupDataCommand(backupCardLinkingKey: currentBackupCard.linkingKey, accessCode: accessCode)
        command.run(in: session) { result in
            switch result {
            case .success(let response):
                self.backupData[currentBackupCard.cardId] = response.data
                self.readBackupData(session: session, index: index + 1, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func getLinkAction(with status: Card.BackupStatus) -> LinkAction {
        switch status {
        case .cardLinked, .active:
            if attestSignature != nil {
                //We already have attest signature and card already linked. Can skip linking
                return .skip
            } else {
                //We don't have attest signature, but card already linked. Force retry with new user codes
                return .retry
            }
        case .noBackup:
            return .link
        }
    }
}

@available(iOS 13.0, *)
private extension FinalizeOriginCardTask {
    enum LinkAction {
        case link
        case skip
        case retry
    }
}
