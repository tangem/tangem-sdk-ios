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
public final class ScanTask: CardSessionRunnable, PreflightReadSetupable {
    public typealias CommandResponse = Card
	
    var preflightReadSettings: PreflightReadTask.Settings {
        walletIndex != nil ? .readWallet(index: walletIndex!) : .fullCardRead
    }
    
	private var walletIndex: WalletIndex?
    private let cardVerification: Bool
    
    public init(cardVerification: Bool = false, walletIndex: WalletIndex? = nil) {
		self.walletIndex = walletIndex
        self.cardVerification = cardVerification
	}
    
    deinit {
        Log.debug("ScanTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard var card = session.environment.card else {
            completion(.failure(.cardError))
            return
        }
        
        card.isPin1Default = session.environment.pin1.isDefault
        
        completion(.success(card))
        return
        
        if let fw = card.firmwareVersionValue, fw > 1.19, //skip old card with persistent SD
           !(card.settingsMask?.contains(.prohibitDefaultPIN1) ?? false) {
            CheckPinCommand().run(in: session) { checkPinResult in
                switch checkPinResult {
                case .success(let checkPinResponse):
                    card.isPin2Default = checkPinResponse.isPin2Default
                    session.environment.card = card
                    self.runCheckWalletIfNeeded(card, session, completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            session.environment.card = card
            runCheckWalletIfNeeded(card, session, completion)
        }
    }
    
    private func runCheckWalletIfNeeded(_ card: Card, _ session: CardSession, _ completion: @escaping CompletionResult<Card>) {
        guard let cardStatus = card.status, cardStatus == .loaded else {
            completion(.success(card))
            return
        }
        
        guard let curve = card.curve,
            let publicKey = card.walletPublicKey else {
                completion(.failure(.cardError))
                return
        }
        
		CheckWalletCommand(curve: curve, publicKey: publicKey).run(in: session) { checkWalletResult in
            switch checkWalletResult {
            case .success(_):
                self.runVerificationIfNeeded(card, session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func runVerificationIfNeeded(_ card: Card, _ session: CardSession, _ completion: @escaping CompletionResult<Card>) {
        guard cardVerification else {
            completion(.success(card))
            return
        }
        
        VerifyCardCommand().run(in: session) { checkWalletResult in
            switch checkWalletResult {
            case .success(_):
                completion(.success(card))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
