//
//  StartPrimaryCardLinkingTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 30.11.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation


@available(iOS 13.0, *)
public class StartPrimaryCardLinkingTask: CardSessionRunnable {
    private var attestationTask: AttestationTask? = nil
    
    public init() {}
    
    deinit {
        Log.debug("StartPrimaryCardLinkingTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<PrimaryCard>) {
        let linkingCommand = StartPrimaryCardLinkingCommand()
        linkingCommand.run(in: session) { result in
            switch result {
            case .success(let rawCard):
                self.runAttestation(rawCard, session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func runAttestation(_ rawCard: RawPrimaryCard, _ session: CardSession, _ completion: @escaping CompletionResult<PrimaryCard>) {
        attestationTask = AttestationTask(mode: .full)
        attestationTask!.run(in: session) { result in
            switch result {
            case .success:
                guard let signature = session.environment.card?.issuerSignature else {
                    completion(.failure(.certificateSignatureRequired))
                    return
                }
                
                let backupCard = PrimaryCard(rawCard, issuerSignature: signature)
                completion(.success(backupCard))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
