//
//  AttestationTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 16.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public final class AttestationTask: CardSessionRunnable {
    public typealias Response = Attestation
    
    private let mode: Mode
    private let trustedCardsRepo: TrustedCardsRepo = .init()
    private let onlineCardVerifier = OnlineCardVerifier()
    
    private var currentAttestationStatus: Attestation = .skipped
    private var onlinePublisher = CurrentValueSubject<Void?, TangemSdkError>(nil)
    private var bag = Set<AnyCancellable>()
    
    
    /// If `true'`, AttestationTask will not pause nfc session after all card operatons complete. Usefull for chaining  tasks after AttestationTask. False by default
    public var shouldKeepSeesionOpened = false
    
    public init(mode: Mode) {
        self.mode = mode
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
    
    public func retryOnline( _ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        onlinePublisher = CurrentValueSubject<Void?, TangemSdkError>(nil)
        
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        runOnlineAttestation(card)
        waitForOnlineAndComplete(session, completion)
    }
    
    private func attestCard(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        AttestCardKeyCommand().run(in: session) { checkWalletResult in
            switch checkWalletResult {
            case .success:
                //This card already attested
                if let attestation = self.trustedCardsRepo.data[session.environment.card!.cardPublicKey] {
                    self.currentAttestationStatus = attestation
                    self.complete(session, completion)
                    return
                }
                
                //Continue attestation
                self.currentAttestationStatus.cardKeyAttestation = .verifiedOffline
                self.continueAttestaton(session, completion)
            case .failure(let error):
                //Card attestation failed. Update status and continue attestation
                if case TangemSdkError.cardVerificationFailed = error {
                    self.currentAttestationStatus.cardKeyAttestation = .failed
                    self.continueAttestaton(session, completion)
                    return
                }
                
                completion(.failure(error))
            }
        }
    }
    
    private func continueAttestaton(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        let card = session.environment.card!
        runOnlineAttestation(card)
        
        switch self.mode {
        case .normal:
            self.waitForOnlineAndComplete(session, completion)
        case .full:
            self.runWalletsAttestation(session, completion)
        }
    }
    
    private func runWalletsAttestation(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        attestWallets(session) { result in
            switch result {
            case .success:
                //Wallets attestation completed. Update status and continue attestation
                self.currentAttestationStatus.walletKeysAttestation = .verified
                self.runExtraAttestation(session, completion)
            case .failure(let error):
                //Wallets attestation failed. Update status and continue attestation
                if case TangemSdkError.cardVerificationFailed = error {
                    self.currentAttestationStatus.walletKeysAttestation = .failed
                    self.runExtraAttestation(session, completion)
                    return
                }
                
                completion(.failure(error))
            }
        }
    }
    
    private func runExtraAttestation(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        //TODO: ATTEST_CARD_FIRMWARE, ATTEST_CARD_UNIQUENESS
        self.waitForOnlineAndComplete(session, completion)
    }
    
    private func attestWallets(_ session: CardSession, _ completion: @escaping CompletionResult<Void>) {
        DispatchQueue.global(qos: .userInitiated).async {
            let card = session.environment.card!
            let walletsKeys = card.wallets.map{ $0.publicKey }
            let attestationCommands = walletsKeys.map { AttestWalletKeyCommand(publicKey: $0) }
            
            let group = DispatchGroup()
            var shoulReturn = false
            for command in attestationCommands {
                if shoulReturn { return }
                group.enter()
                
                command.run(in: session) { result in
                    if case let .failure(error) = result {
                        shoulReturn = true
                        completion(.failure(error))
                    }
                    group.leave()
                }
                
                group.wait()
            }
            completion(.success(()))
        }
    }
    
    private func runOnlineAttestation(_ card: Card) {
        //Dev card will not pass online attestation. Or, if the card already failed offline attestation, we can skip online part.
        //So, we can send the error to the publisher immediately
        if card.firmwareVersion.type == .sdk || card.attestation.cardKeyAttestation == .failed {
            onlinePublisher.send(completion: .failure(.cardVerificationFailed))
            return
        }
        
        onlineCardVerifier
            .getCardInfo(cardId: card.cardId, cardPublicKey: card.cardPublicKey)
            .sink(receiveCompletion: { receivedCompletion in
                if case let .failure(error) = receivedCompletion {
                    self.onlinePublisher.send(completion: .failure(error.toTangemSdkError()))
                }
            }, receiveValue: { _ in
                self.onlinePublisher.send(())
            }).store(in: &bag)
    }
    
    private func waitForOnlineAndComplete( _ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        if !shouldKeepSeesionOpened {
            session.pause() //Nothing to do with nfc anymore
            session.viewDelegate.showUndefinedSpinner()
        }
        
        onlinePublisher
            .compactMap { $0 }
            .sink(receiveCompletion: {[unowned self] receivedCompletion in
                //We interest only in cardVerificationFailed error, ignore network errors
                if case let .failure(error) = receivedCompletion,
                   case TangemSdkError.cardVerificationFailed = error {
                        self.currentAttestationStatus.cardKeyAttestation = .failed
                }
                
                self.complete(session, completion)
                
            }, receiveValue: {[unowned self] _ in
                //We assume, that card verified, because we skip online attestation for dev cards and cards that failed keys attestation
                self.currentAttestationStatus.cardKeyAttestation = .verified
                self.trustedCardsRepo.append(cardPublicKey: session.environment.card!.cardPublicKey, attestation:  self.currentAttestationStatus)
                self.complete(session, completion)
            })
            .store(in: &bag)
    }
    
    private func complete(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        session.environment.card?.attestation = currentAttestationStatus
        completion(.success(currentAttestationStatus))
    }
}

public extension AttestationTask {
    enum Mode: String, CaseIterable {
        case normal, full
    }
}