//
//  CreateWalletCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `CheckWalletCommand`.
public struct CreateWalletResponse: ResponseCodable {
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
@available(iOS 13.0, *)
public final class CreateWalletCommand: Command {
    public typealias CommandResponse = CreateWalletResponse
    
    public var requiresPin2: Bool {
        return true
    }
	
	private var walletIndex: Int?
	private let config: WalletConfig?
	
	public init(config: WalletConfig?, walletIndex: Int?) {
		self.config = config
		self.walletIndex = walletIndex
	}
    
    deinit {
        print ("CreateWalletCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
		
		func statusError(_ status: CardStatus) -> TangemSdkError? {
			switch status {
			case .empty:
				  return nil
			case .loaded:
				return .alreadyCreated
			case .notPersonalized:
				return .notPersonalized
			case .purged:
				return .cardIsPurged
			}
		}
		
		let isWalletDataAvailable = card.firmwareVersion >= FirmwareConstraints.AvailabilityVersions.walletData
		
        if let status = card.status,
		   let error = statusError(status) {
			
			if isWalletDataAvailable {
				
				if walletIndex == card.walletIndex {
					return error
				}
				
			} else {
				return error
			}
            
        }
		
		if isWalletDataAvailable,
		   let targetIndex = walletIndex,
		   targetIndex >= card.walletsCount ?? 1 {
			return .walletIndexExceedsMaxValue
		}
        
        if card.isActivated {
            return .notActivated
        }
        
        return nil
    }
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        if case .invalidParams = error {
			
			guard let card = card else { return .pin2OrCvcRequired }
			
			if let walletsCount = card.walletsCount,
			   (walletIndex ?? 0) >= walletsCount {
				return .walletIndexExceedsMaxValue
			}
			
			if card.firmwareVersion >= FirmwareConstraints.AvailabilityVersions.pin2IsDefault,
			   card.pin2IsDefault ?? false {
				return .alreadyCreated
			}
			
            return .pin2OrCvcRequired
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
		
		if let index = walletIndex {
			try WalletIndex.index(index).addTlvData(to: tlvBuilder)
		}
		
		if environment.card?.firmwareVersion >= FirmwareConstraints.AvailabilityVersions.walletData,
		   let config = config {
			
			try tlvBuilder.append(.settingsMask, value: config.settingsMask)
				.append(.curveId, value: config.curveId)
			
			if let walletData = try serializeWalletData(config.walletData) {
				try tlvBuilder.append(.walletData, value: walletData)
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
	
	private func serializeWalletData(_ walletData: WalletData) throws -> Data? {
		guard let blockchainName = walletData.blockchainName else {
			return nil
		}
		
		let tlvBuilder = try TlvBuilder()
			.append(.blockchainName, value: blockchainName)
		
		if walletData.tokenSymbol != nil {
			try tlvBuilder
				.append(.tokenSymbol, value: walletData.tokenSymbol)
				.append(.tokenContractAddress, value: walletData.tokenContractAddress)
				.append(.tokenDecimal, value: walletData.tokenDecimal)
		}
		
		return tlvBuilder.serialize()
	}
}
