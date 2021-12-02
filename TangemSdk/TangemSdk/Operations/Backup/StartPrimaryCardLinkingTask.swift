//
//  StartPrimaryCardLinkingTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 30.11.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13.0, *)
public class StartPrimaryCardLinkingTask: CardSessionRunnable {
    private var attestationTask: AttestationTask? = nil
    private let onlineCardVerifier = OnlineCardVerifier()
    private var cancellable: AnyCancellable? = nil
    
    public init() {}
    
    deinit {
        Log.debug("StartPrimaryCardLinkingTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<PrimaryCard>) {
        let linkingCommand = StartPrimaryCardLinkingCommand()
        linkingCommand.run(in: session) { result in
            switch result {
            case .success(let rawCard):
                self.loadIssuerSignature(rawCard, session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func loadIssuerSignature(_ rawCard: RawPrimaryCard, _ session: CardSession, _ completion: @escaping CompletionResult<PrimaryCard>) {
        cancellable = onlineCardVerifier
            .getCardData(cardId: rawCard.cardId, cardPublicKey: rawCard.cardPublicKey)
            .sink(receiveCompletion: { receivedCompletion in
                if case .failure = receivedCompletion {
                    completion(.failure(.issuerSignatureLoadingFailed))
                }
            }, receiveValue: { response in
                guard let signature = response.issuerSignature else {
                    completion(.failure(.issuerSignatureLoadingFailed))
                    return
                }
                
                let primaryCard = PrimaryCard(rawCard, issuerSignature: signature)
                completion(.success(primaryCard))
            })
    }
}
