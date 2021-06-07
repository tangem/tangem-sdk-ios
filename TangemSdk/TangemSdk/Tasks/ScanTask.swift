//
//  ScanTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Task that allows to read Tangem card and verify its private key.
/// Returns data from a Tangem card after successful completion of `ReadCommand` and `CheckWalletCommand`, subsequently.
public final class ScanTask: CardSessionRunnable {
    public typealias Response = Card
    
    private let cardVerification: Bool
    //todo: attestation
    public init(cardVerification: Bool = true) {
        self.cardVerification = cardVerification
	}
    
    deinit {
        Log.debug("ScanTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let card = session.environment.card else {
            completion(.failure(.cardError))
            return
        }
        
        runVerificationIfNeeded(card, session, completion)
    }
    
    private func runVerificationIfNeeded(_ card: Card, _ session: CardSession, _ completion: @escaping CompletionResult<Card>) {
        guard cardVerification else {
            runCheckWalletIfNeeded(card, session, completion)
            return
        }
        
        VerifyCardCommand().run(in: session) { checkWalletResult in
            switch checkWalletResult {
            case .success(_):
                self.runCheckWalletIfNeeded(card, session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func runCheckWalletIfNeeded(_ card: Card, _ session: CardSession, _ completion: @escaping CompletionResult<Card>) {
        guard card.firmwareVersion < .multiwalletAvailable else {
            completion(.success(card))
            return
        }
        
        guard let wallet = card.wallets.first else {
            completion(.success(card))
            return
        }
        
        CheckWalletCommand(publicKey: wallet.publicKey).run(in: session) { checkWalletResult in
            switch checkWalletResult {
            case .success(_):
                completion(.success(card))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
