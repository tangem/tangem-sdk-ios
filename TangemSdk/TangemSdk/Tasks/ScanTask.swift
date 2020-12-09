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
@available(iOS 13.0, *)
public final class ScanTask: CardSessionRunnable, WalletSelectable {
    public typealias CommandResponse = Card
	
	private(set) public var walletIndex: WalletIndex?
	
	public init(walletIndex: WalletIndex? = nil) {
		self.walletIndex = walletIndex
	}
    
    deinit {
        print("ScanTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        if let tag = session.connectedTag, case .slix2 = tag {
            session.readSlix2Tag() { result in
                switch result {
                case .success(let responseApdu):
                    do {
                        let card = try CardDeserializer.deserialize(with: session.environment, from: responseApdu)
                        completion(.success(card))
                    } catch {
                        let sessionError = error.toTangemSdkError()
                        completion(.failure(sessionError))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            return
        }
        
        guard var card = session.environment.card else {
            completion(.failure(.cardError))
            return
        }
        
        card.isPin1Default = session.environment.pin1.isDefault
        
        if let fw = card.firmwareVersionValue, fw > 1.19 { //skip old card with persistent SD
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
        
//        if let pin1 = session.environment.pin1.value, let pin2 = session.environment.pin2.value {
//            let checkPinCommand = SetPinCommand(newPin1: pin1, newPin2: pin2)
//            checkPinCommand.run(in: session) {result in
//                switch result {
//                case .success:
//                    break
//                case .failure(let error):
//                    if error == .invalidParams {
//                        session.environment.pin2 = PinCode(.pin2, value: nil)
//                    }
//                }
//                self.runCheckWalletIfNeeded(card, session, completion)
//            }
//        } else {
//            runCheckWalletIfNeeded(card, session, completion)
//        }
    }
    
    private func runCheckWalletIfNeeded(_ card: Card, _ session: CardSession, _ completion: @escaping CompletionResult<Card>) {
        if let productMask = card.cardData?.productMask, productMask.contains(.tag) {
            completion(.success(card))
            return
        }
        
        guard let cardStatus = card.status, cardStatus == .loaded else {
            completion(.success(card))
            return
        }
        
        guard let curve = card.curve,
            let publicKey = card.walletPublicKey else {
                completion(.failure(.cardError))
                return
        }
        
		CheckWalletCommand(curve: curve, publicKey: publicKey, walletIndex: walletIndex).run(in: session) { checkWalletResult in
            switch checkWalletResult {
            case .success(_):
                completion(.success(card))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}


/// Task that allows to read Tangem card and verify its private key on iOS 11 and iOS 12 only. You should use `ScanTask` for iOS 13 and newer
/*public final class ScanTaskLegacy: CardSessionRunnable {
    public typealias CommandResponse = Card
    public init() {}
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        let readCommand = ReadCommand()
        readCommand.run(in: session) {firstResult in
            switch firstResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(var firstResponse):
                guard let firstChallenge = firstResponse.challenge,
                    let firstSalt = firstResponse.salt,
                    let publicKey = firstResponse.walletPublicKey,
                    let firstHashes = firstResponse.signedHashes else {
                        completion(.success(firstResponse))
                        return
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    readCommand.run(in: session) {secondResult in
                        switch secondResult {
                        case .failure(let error):
                            completion(.failure(error))
                        case .success(let secondResponse):
                            guard let secondHashes = secondResponse.signedHashes,
                                let secondChallenge = secondResponse.challenge,
                                let walletSignature = secondResponse.walletSignature,
                                let secondSalt  = secondResponse.salt else {
                                    completion(.failure(.cardError))
                                    return
                            }
                            
                            if secondHashes > firstHashes {
                                firstResponse.signedHashes = secondHashes
                            }
                            
                            if firstChallenge == secondChallenge || firstSalt == secondSalt {
                                completion(.failure(.verificationFailed))
                                return
                            }
                            
                            if let verifyResult = CryptoUtils.vefify(curve: publicKey.count == 65 ? EllipticCurve.secp256k1 : EllipticCurve.ed25519,
                                                                     publicKey: publicKey,
                                                                     message: firstChallenge + firstSalt,
                                                                     signature: walletSignature) {
                                if verifyResult == true {
                                    completion(.success(secondResponse))
                                } else {
                                    completion(.failure(.cryptoUtilsError))
                                }
                            } else {
                                completion(.failure(.verificationFailed))
                            }
                        }
                    }
                }
            }
        }
    }
}*/
