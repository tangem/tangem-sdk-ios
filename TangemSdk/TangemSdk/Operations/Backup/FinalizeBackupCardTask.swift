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
    private var commandsBag: [Any]  = .init()
    
    init(originCard: LinkableOriginCard, backupCards: [BackupCard], backupData: EncryptedBackupData, attestSignature: Data, accessCode: Data, passcode: Data) {
        self.originCard = originCard
        self.backupCards = backupCards
        self.backupData = backupData
        self.attestSignature = attestSignature
        self.accessCode = accessCode
        self.passcode = passcode
    }
    
    deinit {
        Log.debug("FinalizeBackupCardTask deinit")
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        let command = LinkOriginCardCommand(originCard: originCard,
                                            backupCards: backupCards,
                                            attestSignature: attestSignature,
                                            accessCode: accessCode,
                                            passcode: passcode)
        
        command.run(in: session) { linkResult in
            switch linkResult {
            case .success:
                let writeCommand = WriteBackupDataCommand(backupData: self.backupData,
                                                          accessCode: self.accessCode,
                                                          passcode: self.passcode)
                self.commandsBag.append(writeCommand)
                writeCommand.run(in: session) { writeResult in
                    switch writeResult {
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
}
