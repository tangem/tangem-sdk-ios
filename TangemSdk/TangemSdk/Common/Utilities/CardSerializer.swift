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
		
		let decoder = TlvDecoder(tlv: tlv)
		
        let status: CardStatus = try decoder.decode(.status) //todo: optional ?
        
        var card = Card(cardId: try decoder.decodeOptional(.cardId),
                        manufacturerName: try decoder.decodeOptional(.manufacturerName),
                        cardPublicKey: try decoder.decodeOptional(.cardPublicKey),
                        settingsMask: try decoder.decodeOptional(.settingsMask),
                        issuerPublicKey: try decoder.decodeOptional(.issuerPublicKey),
                        signingMethods: try decoder.decodeOptional(.signingMethod),
                        pauseBeforePin2: try decoder.decodeOptional(.pauseBeforePin2),
                        health: try decoder.decodeOptional(.health),
                        isActivated: try decoder.decode(.isActivated),
                        activationSeed: try decoder.decodeOptional(.activationSeed),
                        paymentFlowVersion: try decoder.decodeOptional(.paymentFlowVersion),
                        userCounter: try decoder.decodeOptional(.userCounter),
                        terminalIsLinked: try decoder.decode(.isLinked),
                        cardData: try deserializeCardData(tlv: tlv),
                        walletsCount: try decoder.decodeOptional(.walletsCount) ?? 1,
                        fwVersion: try decoder.decodeOptional(.firmwareVersion),
                        isPurged: status == .purged,
                        defaultCurve: try decoder.decodeOptional(.curveId),
                        remainingSignatures: try decoder.decodeOptional(.walletRemainingSignatures))
        
		if card.firmwareVersion >= FirmwareConstraints.AvailabilityVersions.pin2IsDefault {
			let pin2IsDefault: String? = try? decoder.decodeOptional(.pin2IsDefault)
			card.pin2IsDefault = pin2IsDefault != nil
		}
        
        if card.firmwareVersion < FirmwareConstraints.AvailabilityVersions.walletData,
           status != .purged, let curve = card.defaultCurve {
            Log.debug("Read card with firmware lower than 4. Creating single wallet for wallets dict")
            let wallet = CardWallet(index: 0,
                                    curve: curve,
                                    settingsMask: card.settingsMask,
                                    publicKey: try decoder.decode(.walletPublicKey),
                                    totalSignedHashes: try decoder.decodeOptional(.walletSignedHashes),
                                    remainingSignatures: card.remainingSignatures)
            card.wallets = [wallet]
        }
		return card
	}
	
	static private func deserializeCardData(tlv: [Tlv]) throws -> CardData? {
		guard let cardDataValue = tlv.value(for: .cardData),
			let cardDataTlv = Tlv.deserialize(cardDataValue) else {
				return nil
		}
		
		let decoder = TlvDecoder(tlv: cardDataTlv)
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
