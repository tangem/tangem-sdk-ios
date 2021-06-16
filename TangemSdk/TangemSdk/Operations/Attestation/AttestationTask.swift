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
    
    private var onlinePublisher = CurrentValueSubject<Void?, TangemSdkError>(nil)
    private var bag = Set<AnyCancellable>()
    
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
    }
    
    private func attestCard(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        AttestCardKeyCommand().run(in: session) { checkWalletResult in
            switch checkWalletResult {
            case .success:
                if let attestation = self.trustedCardsRepo.data[session.environment.card!.cardPublicKey] {
                    self.complete(with: attestation, session, completion)
                    return
                }
                
                self.continueAttestaton(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func continueAttestaton(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        let card = session.environment.card!
        switch self.mode {
        case .normal:
            if card.firmwareVersion.type == .sdk {
                self.complete(with: .normalSuccess, session, completion)
                return
            }
            session.pause()
            runOnlineCheck(card)
            completeOnlineCheck(with: .normalSuccess, session, completion)
        case .full:
            if card.firmwareVersion.type != .sdk {
                runOnlineCheck(card)
            }
            
            self.runAdditionalAttestation(session, completion)
        }
    }
    
    private func runAdditionalAttestation(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        let card = session.environment.card!
        
        //TODO: ATTEST_CARD_FIRMWARE, ATTEST_CARD_UNIQUENESS
        if card.firmwareVersion.type != .sdk {
            completeOnlineCheck(with: .fullSuccess, session, completion)
        } else {
            complete(with: .fullSuccess, session, completion)
        }
    }
    
    private func attestWallets(_ session: CardSession, _ completion: @escaping CompletionResult<Void>) {
        let card = session.environment.card!
        let walletsKeys = card.wallets.map{ $0.publicKey }
        let attestationCommands = walletsKeys.map { AttestWalletKeyCommand(publicKey: $0) }
        var results: [Result<AttestWalletKeyResponse, TangemSdkError>] = []
        
        for command in attestationCommands {
            let semaphore = DispatchSemaphore(value: 1)
            command.run(in: session) { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    completion(.failure(error))
                    return
                }
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
    
    private func runOnlineCheck(_ card: Card) {
        onlineCardVerifier
            .getCardInfo(cardId: card.cardId, cardPublicKey: card.cardPublicKey)
            .sink(receiveCompletion: {[unowned self] receivedCompletion in
                if case let .failure(error) = receivedCompletion {
                    self.onlinePublisher.send(completion: .failure(error.toTangemSdkError()))
                }
            }, receiveValue: {[unowned self] _ in
                self.onlinePublisher.send(())
            }).store(in: &bag)
    }
    
    private func completeOnlineCheck(with attestation: Attestation, _ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        onlinePublisher
            .compactMap { $0 }
            .sink(receiveCompletion: { receivedCompletion in
                if case let .failure(error) = receivedCompletion,
                   case TangemSdkError.cardVerificationFailed = error {
                    completion(.failure(error.toTangemSdkError()))
                    return
                }
                
                //TODO: Lead the user trough ViewDelegate
                self.complete(with: attestation, session, completion)
                
            }, receiveValue: {[unowned self] _ in
                self.trustedCardsRepo.append(cardPublicKey: session.environment.card!.cardPublicKey, attestation: attestation)
                self.complete(with: attestation, session, completion)
            })
            .store(in: &bag)
    }
    
    private func complete(with attestation: Attestation, _ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        session.environment.card?.attestation = attestation
        completion(.success(attestation))
    }
}


public extension AttestationTask {
    enum Mode {
        case normal, full
    }
}
