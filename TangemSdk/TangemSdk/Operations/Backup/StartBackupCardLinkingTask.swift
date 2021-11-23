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
    private let originCard: OriginCard
    private let addedBackupCards: [String]
    private var command: StartBackupCardLinkingCommand? = nil
    
    init(originCard: OriginCard, addedBackupCards: [String]) {
        self.originCard = originCard
        self.addedBackupCards = addedBackupCards
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<BackupCard>) {
        if session.environment.config.handleErrors {
            guard let card = session.environment.card else {
                completion(.failure(.missingPreflightRead))
                return
            }
            
            let originWalletCurves = Set(originCard.walletCurves)
            let backupCardSupportedCurves = Set(card.supportedCurves)
            
            if card.issuer.publicKey != originCard.issuer.publicKey {
                completion(.failure(.backupFailedWrongIssuer))
                return
            }
            
            if card.settings.isHDWalletAllowed != originCard.isHDWalletAllowed {
                completion(.failure(.backupFailedHDWalletSettings))
                return
            }
            
            if !originWalletCurves.isSubset(of: backupCardSupportedCurves) {
                completion(.failure(.backupFailedNotEnoughCurves))
                return
            }
            
            if originCard.existingWalletsCount > card.settings.maxWalletsCount {
                completion(.failure(.backupFailedNotEnoughWallets))
                return
            }
            
            if card.cardId.lowercased() == originCard.cardId.lowercased() {
                completion(.failure(.backupCardRequired))
                return
            }
            
            if addedBackupCards.contains(card.cardId) {
                completion(.failure(.backupCardAlreadyAdded))
                return
            }
        }
        
        self.command = StartBackupCardLinkingCommand(originCardLinkingKey: originCard.linkingKey)
        command?.run(in: session, completion: completion)
    }
    
}
