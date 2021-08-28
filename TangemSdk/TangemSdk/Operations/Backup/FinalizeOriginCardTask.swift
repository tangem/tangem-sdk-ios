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
    
    private var backupData: [String:EncryptedBackupData] = [:]
    
    init(backupCards: [LinkableBackupCard], accessCode: Data, passcode: Data, originCardLinkingKey: Data) {
        self.backupCards = backupCards
        self.accessCode = accessCode
        self.passcode = passcode
        self.originCardLinkingKey = originCardLinkingKey
    }
    
    deinit {
        Log.debug("FinalizeOriginCardTask deinit")
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<FinalizeOriginCardResponse>) {
        let command = LinkBackupCardsCommand(backupCards: backupCards,
                                             accessCode: accessCode,
                                             passcode: passcode,
                                             originCardLinkingKey: originCardLinkingKey)
        
        command.run(in: session) { linkResult in
            switch linkResult {
            case .success(let linkResponse):
                self.readBackupData(session: session, index: 0) { readResult in
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

    private func readBackupData(session: CardSession, index: Int, completion: @escaping CompletionResult<[String:EncryptedBackupData]>) {
        if index >= backupCards.count {
            completion(.success(self.backupData))
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
}
