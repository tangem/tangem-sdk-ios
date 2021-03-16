//
//  PreflightReadTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 15/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

final class PreflightReadTask: CardSessionRunnable {
    typealias CommandResponse = ReadResponse
    
    enum ReadSettings: Equatable {
        case readCardOnly
        case fullCardRead
        case readWallet(index: WalletIndex)
    }
    
    var needPreflightRead: Bool { false }
    
    private var readMode: ReadMode = .readCard
    
    private var readSettings: ReadSettings
    
    private var walletIndex: WalletIndex?
    
    init(readSettings: ReadSettings) {
        self.readSettings = readSettings
        if case let .readWallet(index) = readSettings {
            self.walletIndex = index
        }
    }
    
    deinit {
        Log.debug("PreflightReadTask deinit")
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<ReadResponse>) {
        ReadCommand(mode: readMode).run(in: session) { (result) in
            switch result {
            case .success(let readResponse):
                self.finalizeRead(in: session, with: readResponse, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        if case .invalidParams = error {
            return .pin1Required
        }
        
        return error
    }
    
    private func finalizeRead(in session: CardSession, with readResponse: ReadResponse, completion: @escaping CompletionResult<ReadResponse>) {
        if readResponse.firmwareVersion < FirmwareConstraints.AvailabilityVersions.walletData || self.readSettings == .readCardOnly {
            completion(.success(readResponse))
            return
        }
        
        switch readSettings {
        case .fullCardRead:
            readWalletsList(in: session, with: readResponse, completion: completion)
        case .readWallet(let index):
            readWallet(at: index, in: session, with: readResponse, completion: completion)
        default:
            break
        }
    }
    
    private func readWallet(at index: WalletIndex, in session: CardSession, with readResponse: ReadResponse, completion: @escaping CompletionResult<ReadResponse>) {
        if readResponse.firmwareVersion < FirmwareConstraints.AvailabilityVersions.walletData {
            if case let .publicKey(pubkey) = index, readResponse.walletPublicKey == pubkey {
                completion(.success(readResponse))
                return
            }
            completion(.failure(TangemSdkError.walletIndexNotSpecified))
            return
        }
        
        ReadWalletCommand(walletIndex: index).run(in: session) { (result) in
            switch result {
            case .success(let walletResponse):
                var card = readResponse
                card.walletsInfo = [walletResponse.walletInfo]
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
                card.walletsInfo = listRepsonse.wallets
                session.environment.card = card
                completion(.success(card))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
}

