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
    private let primaryCard: PrimaryCard
    private let addedBackupCards: [String]
    private var command: StartBackupCardLinkingCommand? = nil
    
    init(primaryCard: PrimaryCard, addedBackupCards: [String]) {
        self.primaryCard = primaryCard
        self.addedBackupCards = addedBackupCards
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<BackupCard>) {
        if session.environment.config.handleErrors {
            guard let card = session.environment.card else {
                completion(.failure(.missingPreflightRead))
                return
            }
            
            let primaryWalletCurves = Set(primaryCard.walletCurves)
            let backupCardSupportedCurves = Set(card.supportedCurves)
            
            if card.issuer.publicKey != primaryCard.issuer.publicKey {
                completion(.failure(.backupFailedWrongIssuer))
                return
            }
            
            if card.settings.isHDWalletAllowed != primaryCard.isHDWalletAllowed {
                completion(.failure(.backupFailedHDWalletSettings))
                return
            }
            
            if !primaryWalletCurves.isSubset(of: backupCardSupportedCurves) {
                completion(.failure(.backupFailedNotEnoughCurves))
                return
            }
            
            if primaryCard.existingWalletsCount > card.settings.maxWalletsCount {
                completion(.failure(.backupFailedNotEnoughWallets))
                return
            }
            
            if card.cardId.lowercased() == primaryCard.cardId.lowercased() {
                completion(.failure(.backupCardRequired))
                return
            }
            
            if addedBackupCards.contains(card.cardId) {
                completion(.failure(.backupCardAlreadyAdded))
                return
            }
        }
        
        self.command = StartBackupCardLinkingCommand(primaryCardLinkingKey: primaryCard.linkingKey)
        command?.run(in: session, completion: completion)
    }
    
}
