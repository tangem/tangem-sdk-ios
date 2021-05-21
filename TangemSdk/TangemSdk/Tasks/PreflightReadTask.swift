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
    /// No card wiil be read at session start. `SessionEnvironment.card` will be empty
    case none
    /// Read only card info without wallet info. Valid for cards with COS v.4 and higher. Older card will always read card and wallet info
    case readCardOnly
    /// Read card info and single wallet specified in associated index `WalletIndex`. Valid for cards with COS v.4 and higher. Older card will always read card and wallet info
    case readWallet(index: WalletIndex)
    /// Read card info and all wallets. Used by default
    case fullCardRead
}

public final class PreflightReadTask {
    typealias CommandResponse = ReadResponse
    
    private var readMode: PreflightReadMode
    
    public init(readMode: PreflightReadMode) {
        self.readMode = readMode
    }
    
    deinit {
        Log.debug("PreflightReadTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<ReadResponse>) {
        Log.debug("=========================== Perform preflight check with settings: \(readMode) ======================")
        ReadCommand().run(in: session) { (result) in
            switch result {
            case .success(let readResponse):
                self.finalizeRead(in: session, with: readResponse, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func finalizeRead(in session: CardSession, with readResponse: ReadResponse, completion: @escaping CompletionResult<ReadResponse>) {
        if readResponse.firmwareVersion < FirmwareConstraints.AvailabilityVersions.walletData || self.readMode == .readCardOnly {
            completion(.success(readResponse))
            return
        }
        
        let resp: (Result<[CardWallet], TangemSdkError>) -> Void = {
            switch $0 {
            case .success(let wallets):
                var card = readResponse
                card.setWallets(wallets)
                session.environment.card = card
                completion(.success(card))
            case .failure(let error):
                completion(.failure(error))
            }
            
        }
        switch readMode {
        case .readWallet(let index):
            readWallet(at: index, in: session, with: readResponse, completion: resp)
        case .fullCardRead:
            readWalletsList(in: session, with: readResponse, completion: resp)
        default:
            break
        }
    }
    
    private func readWallet(at index: WalletIndex, in session: CardSession, with readResponse: ReadResponse, completion: @escaping (Result<[CardWallet], TangemSdkError>) -> Void) {
        ReadWalletCommand(walletIndex: index).run(in: session) { (result) in
            switch result {
            case .success(let response):
                completion(.success([response.wallet]))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func readWalletsList(in session: CardSession, with readResponse: ReadResponse, completion: @escaping (Result<[CardWallet], TangemSdkError>) -> Void) {
        ReadWalletListCommand().run(in: session) { (result) in
            switch result {
            case .success(let listRepsonse):
                completion(.success(listRepsonse.wallets))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
}

