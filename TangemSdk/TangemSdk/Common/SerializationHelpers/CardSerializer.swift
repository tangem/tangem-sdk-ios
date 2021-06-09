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
        
        guard let cardDataValue = tlv.value(for: .cardData),
            let cardDataTlv = Tlv.deserialize(cardDataValue) else {
                throw TangemSdkError.deserializeApduFailed
        }
        
		let decoder = TlvDecoder(tlv: tlv)
        let cardDataDecoder = TlvDecoder(tlv: cardDataTlv)
        
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
        
        let firmwareValue: String = try decoder.decode(.firmwareVersion)
        let firmware = FirmwareVersion(stringValue: firmwareValue)
        let pin2IsDefault: Bool? = firmware >= .pin2IsDefaultAvailable ?
            try decoder.decode(.pin2IsDefault) : nil
        
        let manufacturer = Card.Manufacturer(name: try decoder.decode(.manufacturerName),
                                             manufactureDate: try cardDataDecoder.decode(.manufactureDateTime),
                                             signature: try cardDataDecoder.decode(.cardIDManufacturerSignature))
        
        let issuer = Card.Issuer(name: try cardDataDecoder.decode(.issuerName),
                                 publicKey: try decoder.decode(.issuerPublicKey))
        
        let settings = Card.Settings(signingMethods: try decoder.decode(.signingMethod),
                                     securityDelay: try decoder.decode(.pauseBeforePin2),
                                     mask:  try decoder.decode(.settingsMask),
                                     maxWalletsCount: try decoder.decodeOptional(.walletsCount) ?? 1) //Cos before v4 always has 1 wallet
        
        let defaultCurve: EllipticCurve = try decoder.decode(.curveId)
        //Cos before v4 always has the only one curve
        let supportedCurves: [EllipticCurve] = firmware >= .multiwalletAvailable ?
        EllipticCurve.allCases : [defaultCurve]
            
        var card = Card(cardId: try decoder.decode(.cardId),
                        batchId: try cardDataDecoder.decode(.batchId),
                        cardPublicKey: try decoder.decode(.cardPublicKey),
                        firmwareVersion: firmware,
                        manufacturer: manufacturer,
                        issuer: issuer,
                        settings: settings,
                        terminalIsLinked: try decoder.decode(.isLinked),
                        pin2IsDefault: pin2IsDefault,
                        supportedCurves: supportedCurves,
                        health: try decoder.decode(.health),
                        remainingSignatures: try decoder.decodeOptional(.walletRemainingSignatures))
        
        
        if card.firmwareVersion < .multiwalletAvailable {
            Log.debug("Read card with firmware lower than 4. Creating single wallet for wallets dict")
            let wallet = CardWallet(index: 0,
                                    curve: defaultCurve,
                                    settingsMask: card.settings.mask.toWalletSettingsMask(),
                                    publicKey: try decoder.decode(.walletPublicKey),
                                    totalSignedHashes: try decoder.decodeOptional(.walletSignedHashes),
                                    remainingSignatures: card.remainingSignatures)
            card.wallets = [wallet]
        }
		return card
	}
}
