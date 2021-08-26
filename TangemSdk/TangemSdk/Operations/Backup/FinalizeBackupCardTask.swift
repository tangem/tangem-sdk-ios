//
//  FinalizeBackupCardTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 26.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
class FinalizeBackupCardTask: CardSessionRunnable {
    
    private let originCard: LinkableOriginCard
    private let backupCards: [BackupCard]
    private let backupData: EncryptedBackupData
    private let attestSignature: Data
    private let accessCode: Data
    private let passcode: Data
    
    init(originCard: LinkableOriginCard, backupCards: [BackupCard], backupData: EncryptedBackupData, attestSignature: Data, accessCode: Data, passcode: Data) {
        self.originCard = originCard
        self.backupCards = backupCards
        self.backupData = backupData
        self.attestSignature = attestSignature
        self.accessCode = accessCode
        self.passcode = passcode
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        linkOriginCard(session: session) { linkResult in
            switch linkResult {
            case .success:
                self.writeBackupData(session: session) { writeReslut in
                    switch writeReslut {
                    case .success(let writeResponse):
                        completion(.success(SuccessResponse(cardId: writeResponse.cardId)))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func linkOriginCard(session: CardSession, completion: @escaping CompletionResult<LinkOriginCardResponse>) {
        let command = LinkOriginCardCommand(originCard: originCard,
                                            backupCards: backupCards,
                                            attestSignature: attestSignature,
                                            accessCode: accessCode,
                                            passcode: passcode)
        
        command.run(in: session, completion: completion)
    }
    
    private func writeBackupData(session: CardSession, completion: @escaping CompletionResult<WriteBackupDataResponse>) {
        let command = WriteBackupDataCommand(backupData: backupData,
                                             accessCode: accessCode,
                                             passcode: passcode)
        
        command.run(in: session, completion: completion)
    }
}
