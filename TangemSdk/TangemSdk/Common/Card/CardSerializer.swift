//
//  CardSerializer.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct CardDeserializer {
	static func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadResponse {
		guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
			throw TangemSdkError.deserializeApduFailed
		}
		
		let decoder = DefaultTlvDecoder(tlv: tlv)
		
		var card = ReadResponse(
			cardId: try decoder.decodeOptional(.cardId),
			manufacturerName: try decoder.decodeOptional(.manufacturerName),
			status: try decoder.decodeOptional(.status),
			firmwareVersion: try decoder.decodeOptional(.firmwareVersion),
			cardPublicKey: try decoder.decodeOptional(.cardPublicKey),
			settingsMask: try decoder.decodeOptional(.settingsMask),
			issuerPublicKey: try decoder.decodeOptional(.issuerPublicKey),
			curve: try decoder.decodeOptional(.curveId),
			maxSignatures: try decoder.decodeOptional(.maxSignatures),
			signingMethods: try decoder.decodeOptional(.signingMethod),
			pauseBeforePin2: try decoder.decodeOptional(.pauseBeforePin2),
			walletPublicKey: try decoder.decodeOptional(.walletPublicKey),
			walletRemainingSignatures: try decoder.decodeOptional(.walletRemainingSignatures),
			walletSignedHashes: try decoder.decodeOptional(.walletSignedHashes),
			health: try decoder.decodeOptional(.health),
			isActivated: try decoder.decode(.isActivated),
			activationSeed: try decoder.decodeOptional(.activationSeed),
			paymentFlowVersion: try decoder.decodeOptional(.paymentFlowVersion),
			userCounter: try decoder.decodeOptional(.userCounter),
			terminalIsLinked: try decoder.decode(.isLinked),
			cardData: try deserializeCardData(tlv: tlv),
			remainingSignatures: try decoder.decodeOptional(.walletRemainingSignatures),
			signedHashes: try decoder.decodeOptional(.walletSignedHashes),
			challenge: try decoder.decodeOptional(.challenge),
			salt: try decoder.decodeOptional(.salt),
			walletSignature: try decoder.decodeOptional(.walletSignature),
			walletIndex: try decoder.decodeOptional(.walletIndex),
			walletsCount: try decoder.decodeOptional(.walletsCount))
		
		if card.firmwareVersion >= FirmwareConstraints.AvailabilityVersions.pin2IsDefault {
			let pin2IsDefault: String? = try? decoder.decodeOptional(.pin2IsDefault)
			card.pin2IsDefault = pin2IsDefault != nil
		}
        
        if card.firmwareVersion < FirmwareConstraints.AvailabilityVersions.walletData, let cardStatus = card.status {
            Log.debug("Read card with firmware lower than 4. Creating single wallet for wallets dict")
            card.wallets[0] = CardWallet(index: 0,
                                         status: WalletStatus(from: cardStatus),
                                         curve: card.curve,
                                         settingsMask: card.settingsMask,
                                         publicKey: card.walletPublicKey,
                                         signedHashes: card.walletSignedHashes)
        }
        
        // Add condition for creating new wallet info structure for old cards
		return card
	}
	
	static private func deserializeCardData(tlv: [Tlv]) throws -> CardData? {
		guard let cardDataValue = tlv.value(for: .cardData),
			let cardDataTlv = Tlv.deserialize(cardDataValue) else {
				return nil
		}
		
		let decoder = DefaultTlvDecoder(tlv: cardDataTlv)
		let cardData = CardData(
			batchId: try decoder.decodeOptional(.batchId),
			manufactureDateTime: try decoder.decodeOptional(.manufactureDateTime),
			issuerName: try decoder.decodeOptional(.issuerName),
			blockchainName: try decoder.decodeOptional(.blockchainName),
			manufacturerSignature: try decoder.decodeOptional(.cardIDManufacturerSignature),
			productMask: try decoder.decodeOptional(.productMask),
			tokenSymbol: try decoder.decodeOptional(.tokenSymbol),
			tokenContractAddress: try decoder.decodeOptional(.tokenContractAddress),
			tokenDecimal: try decoder.decodeOptional(.tokenDecimal))
		
		return cardData
	}
}
