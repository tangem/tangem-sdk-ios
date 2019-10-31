//
//  ScanTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public enum ScanEvent {
    case onRead(Card)
    case onVerify(Bool)
}

public final class ScanTask: Task<ScanEvent> {
    override public func onRun(environment: CardEnvironment, callback: @escaping (TaskEvent<ScanEvent>) -> Void) {
        if #available(iOS 13.0, *) {
            scanWithNfc(environment: environment, callback: callback)
        } else {
            scanWithNdef(environment: environment, callback: callback)
        }
    }
    
    func scanWithNdef(environment: CardEnvironment, callback: @escaping (TaskEvent<ScanEvent>) -> Void) {
        let readCommand = ReadCommand()
        sendCommand(readCommand, environment: environment) { firstResult in
            switch firstResult {
            case .failure(let error):
                callback(.completion(error))
                self.cardReader.stopSession()
            case .success(var firstResponse):
                guard let firstChallenge = firstResponse.challenge,
                    let firstSalt = firstResponse.salt,
                    let publicKey = firstResponse.walletPublicKey,
                    let firstHashes = firstResponse.signedHashes else {
                        self.cardReader.stopSession()
                        callback(.event(.onRead(firstResponse))) //card has no wallet
                        callback(.completion())
                        return
                }
                
                self.sendCommand(readCommand, environment: environment) { secondResult in
                    switch secondResult {
                    case .failure(let error):
                        callback(.completion(error))
                        self.cardReader.stopSession()
                    case .success(let secondResponse):
                        callback(.event(.onRead(secondResponse)))
                        guard let secondHashes = secondResponse.signedHashes,
                            let secondChallenge = secondResponse.challenge,
                            let walletSignature = secondResponse.walletSignature,
                            let secondSalt  = secondResponse.salt else {
                                callback(.completion(TaskError.cardError))
                                self.cardReader.stopSession()
                                return
                        }
                        
                        if secondHashes > firstHashes {
                            firstResponse.signedHashes = secondHashes
                        }
                        
                        if firstChallenge == secondChallenge || firstSalt == secondSalt {
                            callback(.event(.onVerify(false)))
                            callback(.completion())
                            self.cardReader.stopSession()
                            return
                        }
                        
                        if let verifyResult = CryptoUtils.vefify(curve: publicKey.count == 65 ? EllipticCurve.secp256k1 : EllipticCurve.ed25519,
                                                                 publicKey: publicKey,
                                                                 message: firstChallenge + firstSalt,
                                                                 signature: walletSignature) {
                            callback(.event(.onVerify(verifyResult)))
                            callback(.completion())
                        } else {
                            callback(.completion(TaskError.vefificationFailed))
                        }
                        self.cardReader.stopSession()
                    }
                }
            }
        }
    }
    
    @available(iOS 13.0, *)
    func scanWithNfc(environment: CardEnvironment, callback: @escaping (TaskEvent<ScanEvent>) -> Void) {
        let readCommand = ReadCommand()
        sendCommand(readCommand, environment: environment) { [weak self] readResult in
            switch readResult {
            case .failure(let error):
                self?.cardReader.stopSession(errorMessage: error.localizedDescription)
                callback(.completion(error))
            case .success(let readResponse):
                callback(.event(.onRead(readResponse)))
                guard let cardStatus = readResponse.status, cardStatus == .loaded else {
                    self?.cardReader.stopSession()
                    callback(.completion())
                    return
                }
                
                guard let curve = readResponse.curve,
                    let publicKey = readResponse.walletPublicKey else {
                        let error = TaskError.cardError
                        self?.cardReader.stopSession(errorMessage: error.localizedDescription)
                        callback(.completion(error))
                        return
                }
                
                guard let challenge = CryptoUtils.generateRandomBytes(count: 16) else {
                    let error = TaskError.cardError
                    self?.cardReader.stopSession(errorMessage: error.localizedDescription)
                    callback(.completion(error))
                    return
                }
                
                let checkWalletCommand = CheckWalletCommand(pin1: environment.pin1, cardId: readResponse.cardId, challenge: challenge)
                self?.sendCommand(checkWalletCommand, environment: environment) {[weak self] checkWalletResult in
                    switch checkWalletResult {
                    case .failure(let error):
                        self?.cardReader.stopSession(errorMessage: error.localizedDescription)
                        callback(.completion(error))
                    case .success(let checkWalletResponse):
                        self?.delegate?.showAlertMessage(Localization.nfcAlertDefaultDone)
                        self?.cardReader.stopSession()
                        if let verifyResult = CryptoUtils.vefify(curve: curve,
                                                                 publicKey: publicKey,
                                                                 message: challenge + checkWalletResponse.salt,
                                                                 signature: checkWalletResponse.walletSignature) {
                            callback(.event(.onVerify(verifyResult)))
                            callback(.completion())
                        } else {
                            callback(.completion(TaskError.vefificationFailed))
                        }
                    }
                }
            }
        }
    }
}
