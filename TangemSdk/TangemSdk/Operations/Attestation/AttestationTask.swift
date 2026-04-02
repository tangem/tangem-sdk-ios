//
//  AttestationTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 16.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public final class AttestationTask: CardSessionRunnable {
    private let mode: Mode
    private let networkService: NetworkService
    private let trustedCardsRepo: TrustedCardsRepo = .init()
    private var currentAttestationStatus: Attestation = .empty

    /// If `true'`, AttestationTask will not pause nfc session after all card operatons complete. Usefull for chaining  tasks after AttestationTask. False by default
    public var shouldKeepSessionOpened = false

    public init(mode: Mode, networkService: NetworkService) {
        self.mode = mode
        self.networkService = networkService
    }

    deinit {
        Log.debug("AttestationTask deinit")
    }

    public func run(in session: CardSession, completion: @escaping CompletionResult<Attestation>) {
        guard session.environment.card != nil else {
            completion(.failure(.missingPreflightRead))
            return
        }

        attestCard(session, completion)
    }

    private func attestCard(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        let command = AttestCardKeyCommand()
        command.run(in: session) { result in
            switch result {
            case .success:
                // This card already attested with the current or more secured mode
                if let attestation = self.trustedCardsRepo.attestation(for: session.environment.card!.cardPublicKey),
                   attestation.mode >= self.mode {
                    self.currentAttestationStatus = attestation
                    self.complete(session, completion)
                    return
                }

                // Continue attestation
                self.currentAttestationStatus.cardKeyAttestation = .verifiedOffline
                self.continueAttestation(session, completion)
            case .failure(let error):
                // Card attestation failed. Update status and fail attestation
                if case TangemSdkError.cardVerificationFailed = error {
                    self.currentAttestationStatus.cardKeyAttestation = .failed
                }

                completion(.failure(error))
            }

            withExtendedLifetime(command) {}
        }
    }

    private func continueAttestation(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        switch mode {
        case .offline:
            complete(session, completion)
        case .normal:
            runOnlineAttestation(session, completion)
        case .full:
            runWalletsAttestation(session, completion)
        }
    }

    private func runWalletsAttestation(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        attestWallets(session) { result in
            switch result {
            case .success(let hasWarnings):
                // Wallets attestation completed. Update status and continue attestation
                self.currentAttestationStatus.walletKeysAttestation = hasWarnings ? .warning : .verified
                self.runExtraAttestation(session, completion)
            case .failure(let error):
                // Wallets attestation failed. Update status and fail attestation
                if case TangemSdkError.cardVerificationFailed = error {
                    self.currentAttestationStatus.walletKeysAttestation = .failed
                }

                completion(.failure(error))
            }
        }
    }

    private func runExtraAttestation(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        // TODO: ATTEST_CARD_FIRMWARE, ATTEST_CARD_UNIQUENESS
        runOnlineAttestation(session, completion)
    }

    private func attestWallets(_ session: CardSession, _ completion: @escaping CompletionResult<Bool>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        if let error = card.assertWalletsAccess() {
            completion(.failure(error))
            return
        }

        let attestationCommands = card.wallets.compactMap { wallet -> AttestWalletKeyTask? in
            guard let publicKey = wallet.publicKey else {
                return nil
            }

            return AttestWalletKeyTask(walletPublicKey: publicKey)
        }

        if attestationCommands.isEmpty {
            completion(.success(false)) // no warnings
            return
        }

        let hasWarnings = session.environment.card!.wallets.compactMap { $0.totalSignedHashes }
            .contains(where: { $0 > Constants.maxCounter })

        attestWallet(attestationCommands, commandIndex: 0, hasWarnings: hasWarnings, session, completion)
    }

    private func attestWallet(
        _ attestationCommands: [AttestWalletKeyTask],
        commandIndex: Int,
        hasWarnings: Bool,
        _ session: CardSession,
        _ completion: @escaping CompletionResult<Bool>
    ) {
        if commandIndex == attestationCommands.count {
            completion(.success(hasWarnings))
            return
        }

        attestationCommands[commandIndex].run(in: session) { result in
            switch result {
            case .success(let response):
                // check for hacking attempts with attestWallet
                let shouldWarn = response.counter.map { $0 > Constants.maxCounter } ?? false

                self.attestWallet(
                    attestationCommands,
                    commandIndex: commandIndex + 1,
                    hasWarnings: shouldWarn ? true : hasWarnings,
                    session,
                    completion
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func runOnlineAttestation(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        let factory = OnlineAttestationServiceFactory(networkService: networkService)
        let onlineAttestationService = factory.makeService(for: card)

        if !shouldKeepSessionOpened {
            session.pause() // Nothing to do with nfc anymore
        }

        Task {
            let attestResult: Attestation.Status
            let mapper = OnlineAttestationResponseMapper(card: card)

            do {
                let onlineAttestResult = try await onlineAttestationService.attestCard()
                attestResult = mapper.mapValue(onlineAttestResult)
            } catch {
                attestResult = mapper.mapError(error)
            }

            switch attestResult {
            case .verified:
                self.currentAttestationStatus.cardKeyAttestation = .verified
                self.trustedCardsRepo.append(cardPublicKey: session.environment.card!.cardPublicKey, attestation: self.currentAttestationStatus)
            case .failed:
                self.currentAttestationStatus.cardKeyAttestation = .failed
            default:
                break
            }

            await MainActor.run {
                self.processAttestationReport(session, completion)
            }
        }
    }

    private func retryOnline(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        runOnlineAttestation(session, completion)
    }

    private func processAttestationReport(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        switch currentAttestationStatus.status {
        case .failed, .skipped:
            session.viewDelegate.setState(.empty)
            let isDevelopmentCard = session.environment.card!.firmwareVersion.type == .sdk

            if isDevelopmentCard, Config.isDevelopmentMode {
                complete(session, completion)
                return
            }

            if isDevelopmentCard {
                session.viewDelegate.attestationDidFailDevCard { [weak self] in
                    self?.complete(session, completion)
                } onCancel: {
                    completion(.failure(.userCancelled))
                }

                return
            }

            completion(.failure(.cardVerificationFailed))

        case .verified:
            complete(session, completion)

        case .verifiedOffline:
            if session.environment.config.attestationMode == .offline {
                complete(session, completion)
                return
            }

            session.viewDelegate.setState(.empty)
            session.viewDelegate.attestationCompletedOffline { [weak self] in
                self?.complete(session, completion)
            } onCancel: {
                completion(.failure(.userCancelled))
            } onRetry: { [weak self] in
                session.viewDelegate.setState(.default)
                self?.retryOnline(session, completion)
            }

        case .warning:
            session.viewDelegate.setState(.empty)
            session.viewDelegate.attestationCompletedWithWarnings { [weak self] in
                self?.complete(session, completion)
            }
        }
    }

    private func complete(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        session.environment.card?.attestation = currentAttestationStatus
        completion(.success(currentAttestationStatus))
    }
}

public extension AttestationTask {
    enum Mode: String, StringCodable, CaseIterable, Comparable {
        case offline
        case normal
        case full

        public static func < (lhs: AttestationTask.Mode, rhs: AttestationTask.Mode) -> Bool {
            switch (lhs, rhs) {
            case (normal, full):
                return true
            case (offline, normal):
                return true
            case (offline, full):
                return true
            default:
                return false
            }
        }
    }
}

private extension AttestationTask {
    enum Constants {
        /// An attest wallet count or sign command count greater than this value looks suspicious.
        static let maxCounter = 100000
    }
}
