//
//  BackupSession.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct BackupMaster {
    let backupKey: Data
    let cardKey: Data
    var certificate: Data? = nil
}

@available(iOS 13.0, *)
struct BackupSlave {
    let backupKey: Data
    let cardKey: Data
    let attestSignature: Data
    var certificate: Data? = nil
    var encryptionSalt: Data? = nil
    var encryptedData: Data? = nil
    var state: Card.BackupStatus = .noBackup
}

@available(iOS 13.0, *)
struct BackupSession {
    var master: BackupMaster
    var slaves: [String : BackupSlave] = .init()
    var attestSignature: Data? = nil
    var newPIN: Data? = nil
    var newPIN2: Data? = nil
}
