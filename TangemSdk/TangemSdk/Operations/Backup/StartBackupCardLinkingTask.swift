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
    private var attestationTask: AttestationTask? = nil
    
    init(primaryCard: PrimaryCard, addedBackupCards: [String]) {
        self.primaryCard = primaryCard
        self.addedBackupCards = addedBackupCards
    }
    
    deinit {
        Log.debug("StartBackupCardLinkingTask deinit")
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
        
        let linkingCommand = StartBackupCardLinkingCommand(primaryCardLinkingKey: primaryCard.linkingKey)
        linkingCommand.run(in: session) { result in
            switch result {
            case .success(let rawCard):
                self.runAttestation(rawCard, session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func runAttestation(_ rawCard: RawBackupCard, _ session: CardSession, _ completion: @escaping CompletionResult<BackupCard>) {
        attestationTask = AttestationTask(mode: .full)
        attestationTask!.run(in: session) { result in
            switch result {
            case .success:
                guard let signature = session.environment.card?.issuerSignature else {
                    completion(.failure(.certificateSignatureRequired))
                    return
                }
                
                let backupCard = BackupCard(rawCard, issuerSignature: signature)
                completion(.success(backupCard))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
