//
//  PreflightReadTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 15/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Use this protocol when you need to setup preflight read task
/// * Full card - read card info and all wallets
/// * Read wallet - read card info and single wallet specified in associated wallet `WalletIndex`
///
/// If you don't use this protocol SDK will read only card information.
/// - Note: Valid for cards with COS v.4 and higher
protocol PreflightReadSetupable {
    var preflightReadSettings: PreflightReadTask.Settings { get }
}

final class PreflightReadTask {
    typealias CommandResponse = ReadResponse
    
    enum Settings: Equatable {
        case readCardOnly
        case readWallet(index: WalletIndex)
        case fullCardRead
    }
    
    private var readSettings: Settings
    
    init(readSettings: Settings) {
        self.readSettings = readSettings
    }
    
    deinit {
        Log.debug("PreflightReadTask deinit")
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<ReadResponse>) {
        Log.debug("=========================== Perform preflight check with settings: \(readSettings) ======================")
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
        if readResponse.firmwareVersion < FirmwareConstraints.AvailabilityVersions.walletData || self.readSettings == .readCardOnly {
            completion(.success(readResponse))
            return
        }
        
        switch readSettings {
        case .readWallet(let index):
            readWallet(at: index, in: session, with: readResponse, completion: completion)
        case .fullCardRead:
            readWalletsList(in: session, with: readResponse, completion: completion)
        default:
            break
        }
    }
    
    private func readWallet(at index: WalletIndex, in session: CardSession, with readResponse: ReadResponse, completion: @escaping CompletionResult<ReadResponse>) {
        ReadWalletCommand(walletIndex: index).run(in: session) { (result) in
            switch result {
            case .success(let walletResponse):
                let isReadCorrectWallet: Bool
                switch index {
                case .index(let walletIndex):
                    isReadCorrectWallet = walletResponse.walletInfo.index == walletIndex
                case .publicKey(let pubkey):
                    isReadCorrectWallet = walletResponse.walletInfo.publicKey == pubkey
                }
                guard isReadCorrectWallet else {
                    completion(.failure(.cardReadWrongWallet))
                    return
                }
                
                var card = readResponse
                let wallet = walletResponse.walletInfo
                card.wallets = [wallet.index: wallet]
                session.environment.card = card
                completion(.success(card))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func readWalletsList(in session: CardSession, with readResponse: ReadResponse, completion: @escaping CompletionResult<ReadResponse>) {
        ReadWalletListCommand().run(in: session) { (result) in
            switch result {
            case .success(let listRepsonse):
                var card = readResponse
                var wallets: [Int: CardWallet] = [:]
                listRepsonse.wallets.forEach {
                    wallets[$0.index] = $0
                }
                card.wallets = wallets
                session.environment.card = card
                completion(.success(card))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
}

