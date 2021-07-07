//
//  ScanTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Task that allows to read Tangem card and verify its private key.
/// Returns data from a Tangem card after successful completion of `ReadCommand` and `AttestWalletKeyCommand`, subsequently.
public final class ScanTask: CardSessionRunnable {
    public init() {}
    
    deinit {
        Log.debug("ScanTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard session.environment.card != nil else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        runAttestation(session, completion)
    }
    
    private func runAttestation(_ session: CardSession, _ completion: @escaping CompletionResult<Card>) {
        let attestationTask = AttestationTask(mode: session.environment.config.attestationMode)
        attestationTask.run(in: session) { result in
            switch result {
            case .success(let report):
                self.processAttestationReport(report, attestationTask, session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    //TODO: Localize
    private func processAttestationReport(_ report: Attestation, _ attestationTask: AttestationTask, _ session: CardSession, _ completion: @escaping CompletionResult<Card>) {
        switch report.status {
        case .failed, .skipped:
            let isDevelopmentCard = session.environment.card!.firmwareVersion.type == .sdk
            
            //Possible production sample or development card
            if isDevelopmentCard || session.environment.config.allowUnrustedCards {
                let message = isDevelopmentCard ? "This is a development card. You can continue at your own risk"
                    : "This card may be production sample or conterfeit. You can continue at your own risk"
                
                session.viewDelegate.showShouldContinue(title: TangemSdkError.cardVerificationFailed.localizedDescription,
                                                        message: message) {
                    completion(.success(session.environment.card!))
                } onCancel: {
                    completion(.failure(.userCancelled))
                }
                
                return
            }
            
            completion(.failure(.cardVerificationFailed))
            
        case .verified:
            completion(.success(session.environment.card!))
            
        case .verifiedOffline:
            session.viewDelegate.showShouldContinue(title: "Online attestation failed",
                                                    message: "We cannot finish card's online attestation at this time. You can continue at your own risk and try again later, retry now or cancel the operation") {
                completion(.success(session.environment.card!))
            } onCancel: {
                completion(.failure(.userCancelled))
            } onRetry: {
                attestationTask.retryOnline(session) { result in
                    switch result {
                    case .success(let report):
                        self.processAttestationReport(report, attestationTask, session, completion)
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
            
        case .warning:
            let message = "Some wallets on this card has signs of hacking attempts"
            session.viewDelegate.showAlert(title: "Warning", message: message) {
                completion(.success(session.environment.card!))
            }
        }
    }
}
