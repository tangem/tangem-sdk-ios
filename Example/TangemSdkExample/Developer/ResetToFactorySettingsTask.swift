//
//  ResetToFactorySettingsTask.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.11.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class ResetToFactorySettingsTask: CardSessionRunnable {
    func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        deleteWallets(in: session, completion: completion)
    }

    private func deleteWallets(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let wallet = session.environment.card?.wallets.last else {
            deleteMasterSecret(in: session, completion: completion)
            return
        }

        PurgeWalletCommand(walletIndex: wallet.index).run(in: session) { result in
            switch result {
            case .success:
                self.deleteWallets(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func deleteMasterSecret(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard session.environment.card?.masterSecret != nil else {
            resetBackup(in: session, completion: completion)
            return
        }

        PurgeMasterSecretCommand().run(in: session) { result in
            switch result {
            case .success:
                self.resetBackup(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func resetBackup(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard let backupStatus = card.backupStatus,
              backupStatus != .noBackup else {
            self.resetAccessTokens(in: session, completion: completion)
            return
        }

        ResetBackupCommand().run(in: session) { result in
            switch result {
            case .success:
                guard let card = session.environment.card else {
                    completion(.failure(.missingPreflightRead))
                    return
                }

                completion(.success(card))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func resetAccessTokens(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard card.firmwareVersion >= .v8 else {
            completion(.success(card))
            return
        }

        // Nothing to reset if backup required and backup is not done, so we can skip this step
        if card.settings.isBackupRequired {
            completion(.success(card))
            return
        }

        ResetAccessTokensTask().run(in: session) { result in
            switch result {
            case .success:
                guard let card = session.environment.card else {
                    completion(.failure(.missingPreflightRead))
                    return
                }

                completion(.success(card))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
