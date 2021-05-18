//
//  CreateWalletCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `PurgeWalletCommand`.
public struct PurgeWalletResponse: JSONStringConvertible {
    /// Unique Tangem card ID number
    public let cardId: String
    /// Current status of the card [1 - Empty, 2 - Loaded, 3- Purged]
    public let status: CardStatus
    /// Index of purged wallet
    public let walletIndex: WalletIndex
}

/**
 * This command deletes all wallet data. If Is_Reusable flag is enabled during personalization,
 * the card changes state to ‘Empty’ and a new wallet can be created by CREATE_WALLET command.
 * If Is_Reusable flag is disabled, the card switches to ‘Purged’ state.
 * ‘Purged’ state is final, it makes the card useless.
 */
public final class PurgeWalletCommand: Command {
    public typealias CommandResponse = PurgeWalletResponse
    
    public var requiresPin2: Bool {
        return true
    }
	
    public var preflightReadSettings: PreflightReadSettings { .readWallet(index: walletIndex) }
    
    public var walletIndex: WalletIndex
    
    public init(walletIndex: WalletIndex) {
		self.walletIndex = walletIndex
	}
    
    deinit {
        Log.debug("PurgeWalletCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.status == .notPersonalized {
            return .notPersonalized
        }
        
        if card.isActivated {
            return .notActivated
        }
        
        guard let wallet = card.wallet(at: walletIndex) else {
            return .walletNotFound
        }
        
        switch wallet.status {
        case .empty:
            return .walletIsNotCreated
        case .loaded:
            break
        case .purged:
            return .walletIsPurged
        }
        
        if let settingsMask = wallet.settingsMask, settingsMask.contains(.prohibitPurgeWallet) {
            return .purgeWalletProhibited
        }
        
        return nil
    }
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<PurgeWalletResponse>) {
		transieve(in: session) { (result) in
			switch result {
			case .success(let response):
				session.environment.card?.status = .empty
                if var card = session.environment.card,
                   let wallet = card.wallet(at: self.walletIndex) {
                    card.updateWallet(at: self.walletIndex, with: .init(index: wallet.index, status: .empty))
                    session.environment.card = card
                }
                Log.debug(session.environment.card)
				completion(.success(response))
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        if case .invalidParams = error {
            return .pin2OrCvcRequired
        }
        
        return error
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1.value)
            .append(.pin2, value: environment.pin2.value)
            .append(.cardId, value: environment.card?.cardId)
        
		try walletIndex.addTlvData(to: tlvBuilder)
		
        return CommandApdu(.purgeWallet, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> PurgeWalletResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        var index: WalletIndex = walletIndex
        if let respIndex: Int = try decoder.decodeOptional(.walletIndex) {
            index = .index(respIndex)
        }
        return PurgeWalletResponse(
            cardId: try decoder.decode(.cardId),
            status: try decoder.decode(.status),
            walletIndex: index)
    }
}
