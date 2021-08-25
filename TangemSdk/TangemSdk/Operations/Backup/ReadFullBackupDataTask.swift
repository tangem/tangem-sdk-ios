//
//  ReadFullBackupData.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
struct ReadFullBackupDataResponse {
    let slaves: [String:BackupSlave]
}

@available(iOS 13.0, *)
class ReadFullBackupDataTask: CardSessionRunnable {
    private let backupSession: BackupSession
    private var index = 0
    private var slaves: [String:BackupSlave] = [:]
    
    init(backupSession: BackupSession) {
        self.backupSession = backupSession
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<ReadFullBackupDataResponse>) {
        readData(session: session, completion: completion)
    }
    
    private func readData(session: CardSession, completion: @escaping CompletionResult<ReadFullBackupDataResponse>) {
        let valueIndex = backupSession.slaves.values.index(backupSession.slaves.values.startIndex, offsetBy: index)
        
        let command = ReadBackupDataCommand(backupSession: backupSession,
                                            slaveBackupKey: backupSession.slaves.values[valueIndex].backupKey)
        command.run(in: session) { result in
            switch result {
            case .success(let response):
                let slaveValue = self.backupSession.slaves[valueIndex]
                let slaveCardId = slaveValue.key
                var slave = slaveValue.value
                slave.encryptionSalt = response.encryptionSalt
                slave.encryptedData = response.encryptedData
                self.slaves[slaveCardId] = slave
                self.index += 1
                
                if self.index >= self.backupSession.slaves.count {
                    completion(.success(ReadFullBackupDataResponse(slaves: self.slaves)))
                } else {
                    self.readData(session: session, completion: completion)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
