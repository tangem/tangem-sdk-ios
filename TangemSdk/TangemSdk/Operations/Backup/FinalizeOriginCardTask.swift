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
    let attestSignature: Data
    let backupData: [String:EncryptedBackupData]
}

@available(iOS 13.0, *)
class FinalizeOriginCardTask: CardSessionRunnable {
    
    private let backupCards: [LinkableBackupCard]
    private let accessCode: Data
    private let passcode: Data
    private let originCardLinkingKey: Data //only for verification
    
    private var index = 0
    private var backupData: [String:EncryptedBackupData] = [:]
    
    init(backupCards: [LinkableBackupCard], accessCode: Data, passcode: Data, originCardLinkingKey: Data) {
        self.backupCards = backupCards
        self.accessCode = accessCode
        self.passcode = passcode
        self.originCardLinkingKey = originCardLinkingKey
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<FinalizeOriginCardResponse>) {
        linkBackupCards(session: session) { linkResult in
            switch linkResult {
            case .success(let linkResponse):
                self.readBackupData(session: session) { readResult in
                    switch readResult {
                    case .success(let backupData):
                        completion(.success(FinalizeOriginCardResponse(attestSignature: linkResponse.attestSignature,
                                                                       backupData: backupData)))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func linkBackupCards(session: CardSession, completion: @escaping CompletionResult<LinkBackupCardsResponse>) {
        let command = LinkBackupCardsCommand(backupCards: backupCards,
                                             accessCode: accessCode,
                                             passcode: passcode,
                                             originCardLinkingKey: originCardLinkingKey)
        
        command.run(in: session, completion: completion)
    }
    
    private func readBackupData(session: CardSession, completion: @escaping CompletionResult<[String:EncryptedBackupData]>) {
        let currentBackupCard = backupCards[index]
        let command = ReadBackupDataCommand(backupCardLinkingKey: currentBackupCard.linkingKey, accessCode: accessCode)
        command.run(in: session) { result in
            switch result {
            case .success(let response):
                self.backupData[currentBackupCard.cardId] = response.data
                self.index += 1
                
                if self.index >= self.backupCards.count {
                    completion(.success(self.backupData))
                } else {
                    self.readBackupData(session: session, completion: completion)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
