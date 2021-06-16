//
//  PreflightReadTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 15/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Mode for preflight read task
/// - Note: Valid for cards with COS v.4 and higher. Older card will always read the card and the wallet info. `fullCardRead` will be used by default
public enum PreflightReadMode: Equatable {
    /// No card will be read at session start. `SessionEnvironment.card` will be empty
    case none
    /// Read only card info without wallet info. COS 4+. Older card will always read card and wallet info
    case readCardOnly
    /// Read card info and single wallet associated with the specified publicKey. COS 4+. Older card will always read card and wallet info
    case readWallet(publicKey: Data)
    /// Read card info and all wallets. Used by default
    case fullCardRead
}

public final class PreflightReadTask {
    typealias Response = ReadResponse
    
    private let readMode: PreflightReadMode
    private let cardId: String?
    
    public init(readMode: PreflightReadMode, cardId: String?) {
        self.readMode = readMode
        self.cardId = cardId
    }
    
    deinit {
        Log.debug("PreflightReadTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<ReadResponse>) {
        Log.debug("=========================== Perform preflight check with settings: \(readMode) ======================")
        ReadCommand().run(in: session) { (result) in
            switch result {
            case .success(let readResponse):
                if let expectedCardId = self.cardId?.uppercased(),
                   expectedCardId != readResponse.cardId.uppercased() {
                    completion(.failure(.wrongCardNumber))
                    return
                }
                
                if !session.environment.allowedCardTypes.contains(readResponse.firmwareVersion.type) {
                    completion(.failure(.wrongCardType))
                    return
                }
                
                self.finalizeRead(in: session, with: readResponse, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func finalizeRead(in session: CardSession, with readResponse: ReadResponse, completion: @escaping CompletionResult<ReadResponse>) {
        if readResponse.firmwareVersion < .multiwalletAvailable {
            completion(.success(readResponse))
            return
        }
        
        switch readMode {
        case .readWallet(let publicKey):
            readWallet(with: publicKey, in: session, with: readResponse, completion: completion)
        case .fullCardRead:
            readWalletsList(in: session, with: readResponse, completion: completion)
        case .readCardOnly, .none:
            completion(.success(readResponse))
        }
    }
    
    private func readWallet(with publicKey: Data, in session: CardSession, with readResponse: ReadResponse, completion: @escaping CompletionResult<ReadResponse>) {
        ReadWalletCommand(publicKey: publicKey).run(in: session) { (result) in
            switch result {
            case .success:
                completion(.success(readResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func readWalletsList(in session: CardSession, with readResponse: ReadResponse, completion: @escaping CompletionResult<ReadResponse>) {
        ReadWalletsListCommand().run(in: session) { (result) in
            switch result {
            case .success:
                completion(.success(readResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

