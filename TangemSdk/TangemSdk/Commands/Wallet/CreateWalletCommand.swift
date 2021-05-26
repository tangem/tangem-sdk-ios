//
//  CreateWalletCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `CheckWalletCommand`.
public struct CreateWalletResponse: JSONStringConvertible {
    /// Unique Tangem card ID number
    public let cardId: String
    /// Current status of the card [1 - Empty, 2 - Loaded, 3- Purged]
    public let status: CardStatus
	/// Wallet index on card.
	/// - Note: Available only for cards with COS v.4.0 and higher
	public let walletIndex: Int
    /// Public key of a newly created blockchain wallet.
    public let walletPublicKey: Data
}

/**
 * This command will create a new wallet on the card having ‘Empty’ state.
 * A key pair WalletPublicKey / WalletPrivateKey is generated and securely stored in the card.
 * App will need to obtain Wallet_PublicKey from the response of `CreateWalletCommand`or `ReadCommand`
 * and then transform it into an address of corresponding blockchain wallet
 * according to a specific blockchain algorithm.
 * WalletPrivateKey is never revealed by the card and will be used by `SignCommand` and `CheckWalletCommand`.
 * RemainingSignature is set to MaxSignatures.
 */
public final class CreateWalletCommand: Command {
    public typealias CommandResponse = CreateWalletResponse
    
    public var requiresPin2: Bool {
        return true
    }
    
    public var preflightReadMode: PreflightReadMode { .readWallet(index: walletIndex) }
    
    private let walletIndexValue: Int
	private let config: WalletConfig?
    
    private var walletIndex: WalletIndex { .index(walletIndexValue) }
	
	public init(config: WalletConfig? = nil, walletIndex: Int = 0) {
		self.config = config
        self.walletIndexValue = walletIndex
	}
    
    deinit {
        Log.debug("CreateWalletCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.status == .notPersonalized {
            return .notPersonalized
        }
        
        if card.isActivated {
            return .notActivated
        }
        
        guard let wallet = card.wallet(at: walletIndex) else {
            return .walletIndexNotCorrect
        }
        
		func statusError(_ status: WalletStatus) -> TangemSdkError? {
			switch status {
			case .empty:
				  return nil
			case .loaded:
				return .alreadyCreated
			case .purged:
				return .walletIsPurged
			}
		}
		
		let isWalletDataAvailable = card.firmwareVersion >= FirmwareConstraints.AvailabilityVersions.walletData
		
        if let error = statusError(wallet.status) {
			
			if isWalletDataAvailable {
				
				if walletIndexValue == wallet.index {
					return error
				}
				
			} else {
				return error
			}
            
        }
		
		if isWalletDataAvailable,
		   walletIndexValue >= card.walletsCount ?? 1 {
			return .walletIndexExceedsMaxValue
		}
        
        
        return nil
    }
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        if case .invalidParams = error {
			
			guard let card = card else { return error }
			
			if let walletsCount = card.walletsCount,
			   walletIndexValue >= walletsCount {
				return .walletIndexExceedsMaxValue
			}
			
            // If card returns "Invalid params" when it shouldn't, try to check in card SettingsMask "AllowSelectBlockchain" flag :)
			if card.firmwareVersion >= FirmwareConstraints.AvailabilityVersions.pin2IsDefault,
			   card.pin2IsDefault ?? false {
				return .alreadyCreated
			}
        }
        
        return error
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1.value)
            .append(.pin2, value: environment.pin2.value)
            .append(.cardId, value: environment.card?.cardId)
        
        if let cvc = environment.cvc {
            try tlvBuilder.append(.cvc, value: cvc)
        }
		
        try walletIndex.addTlvData(to: tlvBuilder)
		
		if environment.card?.firmwareVersion >= FirmwareConstraints.AvailabilityVersions.walletData,
		   let config = config {
			
            if let settingsMask = config.settingsMask {
                try tlvBuilder.append(.settingsMask, value: settingsMask)
            }
            
            if let curve = config.curveId {
                try tlvBuilder.append(.curveId, value: curve)
            }
            
            if let signingMethods = config.signingMethods {
                try tlvBuilder.append(.signingMethod, value: signingMethods)
            }
		}
        
        return CommandApdu(.createWallet, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> CreateWalletResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return CreateWalletResponse(
            cardId: try decoder.decode(.cardId),
            status: try decoder.decode(.status),
			walletIndex: try decoder.decodeOptional(.walletIndex) ?? 0,
            walletPublicKey: try decoder.decode(.walletPublicKey))
    }
}
