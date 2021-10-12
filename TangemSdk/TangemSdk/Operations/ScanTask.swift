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
@available(iOS 13.0, *)
public final class ScanTask: CardSessionRunnable {
    public init() {}
    
    deinit {
        Log.debug("ScanTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let card = session.environment.card  else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        //We have to retrieve passcode status information for cards with COS before v4.01 with checkUserCodes command for backward compatibility.
        //checkUserCodes command for cards with COS <=1.19 not supported because of persistent SD.
        //We cannot run checkUserCodes command for cards whose `isResettingUserCodesAllowed` is set to false because of an error
        if card.firmwareVersion < .isPasscodeStatusAvailable
            && card.firmwareVersion.doubleValue > 1.19
            && card.settings.isResettingUserCodesAllowed {
            checkUserCodes(session, completion)
        } else {
            runAttestation(session, completion)
        }
    }

    private func checkUserCodes(_ session: CardSession, _ completion: @escaping CompletionResult<Card>) {
        CheckUserCodesCommand().run(in: session) { result in
            switch result {
            case .success(let response):
                session.environment.card?.isPasscodeSet = response.isPasscodeSet
                self.runAttestation(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
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
            session.viewDelegate.setState(.empty)
            //Possible production sample or development card
            if isDevelopmentCard || session.environment.config.allowUntrustedCards {
                session.viewDelegate.attestationDidFail(isDevelopmentCard: isDevelopmentCard) {
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
            session.viewDelegate.setState(.empty)
            session.viewDelegate.attestationCompletedOffline() {
                completion(.success(session.environment.card!))
            } onCancel: {
                completion(.failure(.userCancelled))
            } onRetry: {
                session.viewDelegate.setState(.default)
                
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
            session.viewDelegate.setState(.empty)
            session.viewDelegate.attestationCompletedWithWarnings {
                completion(.success(session.environment.card!))
            }
        }
    }
}
