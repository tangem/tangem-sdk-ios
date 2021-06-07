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
		
        let status: CardStatus = try decoder.decode(.status)
        
        if status == .notPersonalized {
            throw TangemSdkError.notPersonalized
        }
        
        if status == .purged {
            throw TangemSdkError.walletIsPurged
        }
        
        let isNeedActivation: Bool = try decoder.decode(.isActivated)
        if isNeedActivation {
            throw TangemSdkError.notActivated
        }
        
        var card = Card(cardId: try decoder.decode(.cardId),
                        manufacturerName: try decoder.decode(.manufacturerName),
                        cardPublicKey: try decoder.decode(.cardPublicKey),
                        settingsMask: try decoder.decode(.settingsMask),
                        issuerPublicKey: try decoder.decode(.issuerPublicKey),
                        signingMethods: try decoder.decode(.signingMethod),
                        securityDelay: try decoder.decode(.pauseBeforePin2),
                        health: try decoder.decodeOptional(.health),
                        terminalIsLinked: try decoder.decode(.isLinked),
                        cardData: try deserializeCardData(tlv: tlv),
                        maxWalletsCount: try decoder.decodeOptional(.walletsCount) ?? 1,
                        defaultCurve: try decoder.decode(.curveId),
                        remainingSignatures: try decoder.decodeOptional(.walletRemainingSignatures),
                        firmware: try decoder.decode(.firmwareVersion))
        
        if card.firmwareVersion >= .pin2IsDefaultAvailable {
			card.pin2IsDefault = try decoder.decode(.pin2IsDefault)
		}
        
        if card.firmwareVersion < .multiwalletAvailable {
            Log.debug("Read card with firmware lower than 4. Creating single wallet for wallets dict")
            let wallet = CardWallet(index: 0,
                                    curve: card.defaultCurve,
                                    settingsMask: card.settingsMask.toWalletSettingsMask(),
                                    publicKey: try decoder.decode(.walletPublicKey),
                                    totalSignedHashes: try decoder.decodeOptional(.walletSignedHashes),
                                    remainingSignatures: card.remainingSignatures)
            card.wallets = [wallet]
        }
		return card
	}
	
	static private func deserializeCardData(tlv: [Tlv]) throws -> CardData {
		guard let cardDataValue = tlv.value(for: .cardData),
			let cardDataTlv = Tlv.deserialize(cardDataValue) else {
                throw TangemSdkError.deserializeApduFailed
		}
		
		let decoder = TlvDecoder(tlv: cardDataTlv)
		let cardData = CardData(
			batchId: try decoder.decode(.batchId),
			manufactureDateTime: try decoder.decode(.manufactureDateTime),
			issuerName: try decoder.decode(.issuerName),
			blockchainName: try decoder.decode(.blockchainName),
			manufacturerSignature: try decoder.decodeOptional(.cardIDManufacturerSignature),
			productMask: try decoder.decodeOptional(.productMask),
			tokenSymbol: try decoder.decodeOptional(.tokenSymbol),
			tokenContractAddress: try decoder.decodeOptional(.tokenContractAddress),
			tokenDecimal: try decoder.decodeOptional(.tokenDecimal))
		
		return cardData
	}
}
