//
//  StartBackupCardLinkingTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
final class StartBackupCardLinkingTask: CardSessionRunnable {
    private let originCardLinkingKey: Data
    private let addedBackupCards: [String]
    private var command: StartBackupCardLinkingCommand? = nil
    
    init(originCardLinkingKey: Data, addedBackupCards: [String]) {
        self.originCardLinkingKey = originCardLinkingKey
        self.addedBackupCards = addedBackupCards
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<BackupCard>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        if addedBackupCards.contains(card.cardId) {
            completion(.failure(.backupCardAlreadyInList))
            return
        }
        
        self.command = StartBackupCardLinkingCommand(originCardLinkingKey: originCardLinkingKey)
        command?.run(in: session, completion: completion)
    }
    
}
