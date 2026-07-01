//
//  PreflightReadTask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Mode for preflight read task
/// - Note: Valid for cards with COS v.4 and higher. Older card will always read the card and the wallet info. `fullCardRead` will be used by default
public enum PreflightReadMode: Decodable, Equatable {
    /// No card will be read at session start. `SessionEnvironment.card` will be empty
    case none
    /// Read only card info without wallet info. COS 4+. Older card will always read card and wallet info
    case readCardOnly
    /// Read card info and all wallets. Used by default
    case fullCardRead
    /// Read card info and all wallets. Show alert if this card is unknown yet.
    case fullCardReadWithAccessCodeCheck
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        let stringValue = try values.decode(String.self).lowercased()
        
        switch stringValue {
        case "none":
            self = .none
        case "readcardonly":
            self = .readCardOnly
        case "fullcardread":
            self = .fullCardRead
        default:
            throw TangemSdkError.decodingFailed("Failed to decode PreflightReadMode")
        }
    }
}

final class PreflightReadTask: CardSessionRunnable {
    private let readMode: PreflightReadMode
    private let preflightFilter: PreflightReadFilter?
    private let trustedCardsRepo = TrustedCardsRepo()
    
    init(readMode: PreflightReadMode, filter: PreflightReadFilter?) {
        self.readMode = readMode
        preflightFilter = filter
    }
    
    deinit {
        Log.debug("PreflightReadTask deinit")
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        Log.session("Run preflight read with mode: \(readMode)")
        let command = ReadCommand()
        command.run(in: session) { result in
            switch result {
            case .success(let readResponse):
                let (card, _) = readResponse
                
                do {
                    let permanentFilter = session.environment.config.filter
                    try permanentFilter.verifyCard(card)
                    
                    if session.environment.config.handleErrors {
                        try self.preflightFilter?.onCardRead(card, environment: session.environment)
                    }
                    
                } catch {
                    completion(.failure(.preflightFiltered(error)))
                    return
                }
                
                if card.firmwareVersion.type != .sdk {
                    Config.isDevelopmentMode = false
                }
                
                self.updateEnvironmentIfNeeded(for: card, in: session)
                session.fetchAccessCodeIfNeeded()
                session.fetchAccessTokensIfNeeded()
                self.finalizeRead(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
            
            withExtendedLifetime(command) {}
        }
    }
    
    private func finalizeRead(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        if card.firmwareVersion < .multiwalletAvailable {
            do {
                try filterOnReadWalletsList(card: card, session)
            } catch {
                completion(.failure(.preflightFiltered(error)))
                return
            }
            
            completion(.success(card))
            return
        }
        
        switch readMode {
        case .fullCardRead:
            readWalletsList(in: session, completion: completion)
        case .fullCardReadWithAccessCodeCheck:
            if card.isAccessCodeSet, trustedCardsRepo.attestation(for: card.cardPublicKey) == nil {
                session.pause()
                
                let showWelcomeBackWarning: Bool
                if Config.isDevelopmentMode, card.firmwareVersion.type == .sdk {
                    showWelcomeBackWarning = false
                } else {
                    showWelcomeBackWarning = true
                }
                
                DispatchQueue.main.async {
                    session.environment.accessCode = UserCode(.accessCode, value: nil)
                    session.requestUserCode(.accessCode, showWelcomeBackWarning: showWelcomeBackWarning) { result in
                        switch result {
                        case .success:
                            session.resume()
                            self.readWalletsList(in: session, completion: completion)
                        case .failure(let error):
                            session.releaseTag()
                            completion(.failure(error))
                        }
                    }
                }
                
            } else {
                readWalletsList(in: session, completion: completion)
            }
        case .readCardOnly, .none:
            completion(.success(card))
        }
    }
    
    private func readWalletsList(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        let command = ReadWalletsListCommand()
        command.run(in: session) { result in
            switch result {
            case .success(let response):
                guard let card = session.environment.card else {
                    completion(.failure(.missingPreflightRead))
                    return
                }
                
                do {
                    try self.filterOnReadWalletsList(card: card, session)
                } catch {
                    completion(.failure(.preflightFiltered(error)))
                    return
                }
                
                if card.firmwareVersion >= .v8 {
                    self.readMasterSecret(backupHash: response.backupHash, session: session, completion: completion)
                } else {
                    completion(.success(card))
                }
            case .failure(let error):
                completion(.failure(error))
            }
            
            withExtendedLifetime(command) {}
        }
    }
    
    private func readMasterSecret(backupHash: Data?, session: CardSession, completion: @escaping CompletionResult<Card>) {
        let command = ReadMasterSecretCommand()
        command.run(in: session) { result in
            switch result {
            case .success(let response):
                session.environment.card?.masterSecret = response.masterSecret
                self.verifyBackup(backupHash: backupHash, session: session)
                
                guard let card = session.environment.card else {
                    completion(.failure(.missingPreflightRead))
                    return
                }
                
                completion(.success(card))
            case .failure(let error):
                completion(.failure(error))
            }
            
            withExtendedLifetime(command) {}
        }
    }
    
    private func verifyBackup(backupHash: Data?, session: CardSession) {
        guard let backupHash,
              let card = session.environment.card else {
            return
        }
        
        // No backup yet
        if backupHash.allSatisfy({ $0 == 0 }) {
            return
        }
        
        let calculatedHash = Self.calculateBackupHash(card: card)
        let isBackupVerified = CryptoUtils.secureCompare(calculatedHash, backupHash)
        session.environment.card?.isBackupVerified = isBackupVerified
        Log.session("Backup is verified: \(isBackupVerified)")
    }
    
    private static func calculateBackupHash(card: Card) -> Data {
        var hashData = Data("WALLETS".utf8)
        
        // Master secret
        if let masterSecret = card.masterSecret {
            hashData.append(UInt8(masterSecret.status.rawValue) & 0x7F)
            
            if let publicKey = masterSecret.publicKey {
                hashData.append(publicKey)
            }
            
            if let chainCode = masterSecret.chainCode {
                hashData.append(chainCode)
            }
        }
        
        for wallet in card.wallets.sorted(by: { $0.index < $1.index }) {
            hashData.append(wallet.index.byte)
            hashData.append(UInt8(wallet.status.rawValue) & 0x7F)
            
            if let publicKey = wallet.publicKey {
                hashData.append(publicKey)
            }
            
            if let chainCode = wallet.chainCode {
                hashData.append(chainCode)
            }
        }
        
        return hashData.getSHA256().prefix(8)
    }
    
    private func filterOnReadWalletsList(card: Card, _ session: CardSession) throws {
        guard session.environment.config.handleErrors else {
            return
        }
        
        do {
            try preflightFilter?.onFullCardRead(card, environment: session.environment)
        } catch {
            throw TangemSdkError.preflightFiltered(error)
        }
    }
    
    private func updateEnvironmentIfNeeded(for card: Card, in session: CardSession) {
        if FirmwareVersion.visaRange.contains(card.firmwareVersion.doubleValue) {
            session.environment.config.cardIdDisplayFormat = .none
        }
    }
}
