//
//  FinalizeBackupCardTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 26.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class FinalizeBackupCardTask: CardSessionRunnable {
    var shouldAskForAccessCode: Bool { false }

    private let primaryCard: PrimaryCard
    private let backupCards: [BackupCard]
    private let backupData: [EncryptedBackupData]
    private let attestSignature: Data
    private let accessCode: Data
    private let passcode: Data
    private let performDerivations: Bool

    init(
        primaryCard: PrimaryCard,
        backupCards: [BackupCard],
        backupData: [EncryptedBackupData],
        attestSignature: Data,
        accessCode: Data,
        passcode: Data,
        performDerivations: Bool
    ) {
        self.primaryCard = primaryCard
        self.backupCards = backupCards
        self.backupData = backupData
        self.attestSignature = attestSignature
        self.accessCode = accessCode
        self.passcode = passcode
        self.performDerivations = performDerivations
    }

    deinit {
        Log.debug("FinalizeBackupCardTask deinit")
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<FinalizeBackupCardTask.Response>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        switch card.backupStatus {
        case .noBackup: // The direct case
            let linkCommand = LinkPrimaryCardCommand(
                primaryCard: primaryCard,
                backupCards: backupCards,
                attestSignature: attestSignature,
                accessCode: accessCode,
                passcode: passcode
            )

            linkCommand.run(in: session) { linkResult in
                switch linkResult {
                case .success:
                    session.secureChannelSession?.didAuthorizePin(accessLevel: .user)
                    self.writeBackupData(in: session, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }

                withExtendedLifetime(linkCommand) {}
            }
        case .active: // Inconsistency case. The card status is ok, but SDK status is incomplete. We should check all wallets later in the app.
            readWallets(in: session, completion: completion)
        default: // only an interrupted case is possible
            writeBackupData(in: session, completion: completion)
        }
    }

    private func writeBackupData(in session: CardSession, completion: @escaping CompletionResult<FinalizeBackupCardTask.Response>) {
        let writeCommand = WriteBackupDataCommand(
            backupData: backupData,
            accessCode: accessCode
        )

        writeCommand.run(in: session) { writeResult in
            switch writeResult {
            case .success(let writeResponse):
                if writeResponse.backupStatus == .active {
                    self.readWallets(in: session, completion: completion)
                } else {
                    completion(.failure(TangemSdkError.unknownError))
                }
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(writeCommand) {}
        }
    }

    private func readWallets(in session: CardSession, completion: @escaping CompletionResult<FinalizeBackupCardTask.Response>) {
        let readWalletsCommand = ReadWalletsListCommand()

        readWalletsCommand.run(in: session) { result in
            switch result {
            case .success:
                self.deriveKeysIfNeeded(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(readWalletsCommand) {}
        }
    }

    private func deriveKeysIfNeeded(_ session: CardSession, _ completion: @escaping CompletionResult<FinalizeBackupCardTask.Response>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard performDerivations else {
            getAccessTokensIfNeeded(session, completion)
            return
        }

        if card.assertWalletsAccess() != nil {
            getAccessTokensIfNeeded(session, completion)
            return
        }

        let defaultPaths = session.environment.config.defaultDerivationPaths
        guard card.firmwareVersion >= .hdWalletAvailable, card.settings.isHDWalletAllowed, !defaultPaths.isEmpty else {
            getAccessTokensIfNeeded(session, completion)
            return
        }

        let derivations = card.wallets.reduce(into: [Data: [DerivationPath]]()) { result, wallet in
            if let walletPublicKey = wallet.publicKey, let paths = defaultPaths[wallet.curve], !paths.isEmpty {
                result[walletPublicKey] = paths
            }
        }

        guard !derivations.isEmpty else {
            getAccessTokensIfNeeded(session, completion)
            return
        }

        let derivationTask = DeriveMultipleWalletPublicKeysTask(derivations)
        derivationTask.run(in: session) { result in
            switch result {
            case .success:
                self.getAccessTokensIfNeeded(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(derivationTask) {}
        }
    }

    private func getAccessTokensIfNeeded(_ session: CardSession, _ completion: @escaping CompletionResult<FinalizeBackupCardTask.Response>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard card.firmwareVersion >= .v8 else {
            completion(.success(Response(card: card, cardAccessTokens: nil)))
            return
        }

        let command = ManageAccessTokensCommand(mode: .renew)
        command.run(in: session) { result in
            switch result {
            case .success(let response):
                completion(.success(Response(card: card, cardAccessTokens: response.cardAccessTokens)))
            case .failure(let error):
                completion(.failure(error))
            }
            withExtendedLifetime(command) {}
        }
    }
}

extension FinalizeBackupCardTask {
    struct Response {
        let card: Card
        let cardAccessTokens: CardAccessTokens?
    }
}
