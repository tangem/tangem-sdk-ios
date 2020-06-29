//
//  CardConfig.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 22.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation


//{"issuerName":"TANGEM SDK","acquirerName":"Smart Cash","series":"BB","startNumber":300000000000,"count":0,"pin":"000000","pin2":"000","pin3":"","hexCrExKey":"00112233445566778899AABBCCDDEEFFFFEEDDCCBBAA998877665544332211000000111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFF","cvc":"000","pauseBeforePin2":5000,"smartSecurityDelay":true,"curveID":"Secp256k1","signingMethods":{"rawValue":0},"maxSignatures":999999,"isReusable":true,"allowSwapPin":true,"allowSwapPin2":true,"useActivation":false,"useCvc":false,"useNdef":true,"useDynamicNdef":true,"useOneCommandAtTime":false,"useBlock":false,"allowSelectBlockchain":false,"forbidPurgeWallet":false,"protocolAllowUnencrypted":true,"protocolAllowStaticEncryption":true,"protectIssuerDataAgainstReplay":true,"forbidDefaultPin":false,"disablePrecomputedNdef":false,"skipSecurityDelayIfValidatedByIssuer":true,"skipCheckPIN2andCVCIfValidatedByIssuer":true,"skipSecurityDelayIfValidatedByLinkedTerminal":true,"restrictOverwriteIssuerDataEx":false,"requireTerminalTxSignature":false,"requireTerminalCertSignature":false,"checkPin3onCard":true,"createWallet":true,"cardData":{"issuerName":"TANGEM SDK","batchId":"FFFF","blockchainName":"ETH","manufactureDateTime":"2020-06-26","productMask":{"rawValue":1}},"ndefRecords":[{"type":"AAR","value":"com.tangem.wallet"},{"type":"URI","value":"https://tangem.com"}]}


/**
 * It is a configuration file with all the card settings that are written on the card
 * during [PersonalizeCommand].
 */
public struct CardConfig: ResponseCodable {
    let issuerName: String?
    let acquirerName: String?
    let series: String?
    let startNumber: Int64
    let count: Int
    let pin: String
    let pin2: String
    let pin3: String
    let hexCrExKey: String?
    let cvc: String
    let pauseBeforePin2: Int
    let smartSecurityDelay: Bool
    let curveID: EllipticCurve
    let signingMethods: SigningMethod
    let maxSignatures: Int
    let isReusable: Bool
    let allowSwapPin: Bool
    let allowSwapPin2: Bool
    let useActivation: Bool
    let useCvc: Bool
    let useNdef: Bool
    let useDynamicNdef: Bool
    let useOneCommandAtTime: Bool
    let useBlock: Bool
    let allowSelectBlockchain: Bool
    let forbidPurgeWallet: Bool
    let protocolAllowUnencrypted: Bool
    let protocolAllowStaticEncryption: Bool
    let protectIssuerDataAgainstReplay: Bool
    let forbidDefaultPin: Bool
    let disablePrecomputedNdef: Bool
    let skipSecurityDelayIfValidatedByIssuer: Bool
    let skipCheckPIN2andCVCIfValidatedByIssuer: Bool
    let skipSecurityDelayIfValidatedByLinkedTerminal: Bool
    
    let restrictOverwriteIssuerDataEx: Bool
    
    let requireTerminalTxSignature: Bool
    let requireTerminalCertSignature: Bool
    let checkPin3onCard: Bool
    
    let createWallet: Bool
    
    let cardData: CardData
    let ndefRecords: [NdefRecord]
    
    private let Alf = "ABCDEF0123456789"
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        issuerName = try values.decode(String.self, forKey: .issuerName)
        acquirerName = try values.decode(String.self, forKey: .acquirerName)
        series = try values.decode(String.self, forKey: .issuerName)
        startNumber = try values.decode(Int64.self, forKey: .startNumber)
        count = try values.decode(Int.self, forKey: .count)
        pin = try values.decode(String.self, forKey: .pin)
        pin2 = try values.decode(String.self, forKey: .pin2)
        pin3 = try values.decode(String.self, forKey: .pin3)
        hexCrExKey = try values.decode(String.self, forKey: .hexCrExKey)
        cvc = try values.decode(String.self, forKey: .cvc)
        pauseBeforePin2 = try values.decode(Int.self, forKey: .pauseBeforePin2)
        smartSecurityDelay = try values.decode(Bool.self, forKey: .smartSecurityDelay)
        
        let curveString = try values.decode(String.self, forKey: .curveID)
        if let curveID = EllipticCurve(rawValue: curveString.lowercasingFirst()) {
            self.curveID = curveID
        } else {
            throw TangemSdkError.decodingFailed
        }
        
        let signingMethodsDictionary = try values.decode([String:Int].self, forKey: .signingMethods)
        if let rawValue = signingMethodsDictionary["rawValue"]  {
            signingMethods = SigningMethod(rawValue: rawValue)
        } else {
            throw TangemSdkError.decodingFailed
        }
        
        maxSignatures = try values.decode(Int.self, forKey: .maxSignatures)
        isReusable = try values.decode(Bool.self, forKey: .isReusable)
        allowSwapPin = try values.decode(Bool.self, forKey: .allowSwapPin)
        allowSwapPin2 = try values.decode(Bool.self, forKey: .allowSwapPin2)
        useActivation = try values.decode(Bool.self, forKey: .useActivation)
        useCvc = try values.decode(Bool.self, forKey: .useCvc)
        useNdef = try values.decode(Bool.self, forKey: .useNdef)
        useDynamicNdef = try values.decode(Bool.self, forKey: .useDynamicNdef)
        useOneCommandAtTime = try values.decode(Bool.self, forKey: .useOneCommandAtTime)
        useBlock = try values.decode(Bool.self, forKey: .useBlock)
        allowSelectBlockchain = try values.decode(Bool.self, forKey: .allowSelectBlockchain)
        forbidPurgeWallet = try values.decode(Bool.self, forKey: .forbidPurgeWallet)
        protocolAllowUnencrypted = try values.decode(Bool.self, forKey: .protocolAllowUnencrypted)
        protocolAllowStaticEncryption = try values.decode(Bool.self, forKey: .protocolAllowStaticEncryption)
        protectIssuerDataAgainstReplay = try values.decode(Bool.self, forKey: .protectIssuerDataAgainstReplay)
        forbidDefaultPin = try values.decode(Bool.self, forKey: .forbidDefaultPin)
        disablePrecomputedNdef = try values.decode(Bool.self, forKey: .disablePrecomputedNdef)
        skipSecurityDelayIfValidatedByIssuer = try values.decode(Bool.self, forKey: .skipSecurityDelayIfValidatedByIssuer)
        skipCheckPIN2andCVCIfValidatedByIssuer = try values.decode(Bool.self, forKey: .skipCheckPIN2andCVCIfValidatedByIssuer)
        skipSecurityDelayIfValidatedByLinkedTerminal = try values.decode(Bool.self, forKey: .skipSecurityDelayIfValidatedByLinkedTerminal)
        restrictOverwriteIssuerDataEx = try values.decode(Bool.self, forKey: .restrictOverwriteIssuerDataEx)
        requireTerminalTxSignature = try values.decode(Bool.self, forKey: .requireTerminalTxSignature)
        requireTerminalCertSignature = try values.decode(Bool.self, forKey: .requireTerminalCertSignature)
        checkPin3onCard = try values.decode(Bool.self, forKey: .checkPin3onCard)
        createWallet = try values.decode(Bool.self, forKey: .createWallet)
        cardData = try values.decode(CardData.self, forKey: .cardData)
        ndefRecords = try values.decode([NdefRecord].self, forKey: .ndefRecords)
    }
    
    
    func createSettingsMask() -> SettingsMask {
        let builder = SettingsMaskBuilder()
        
        if allowSwapPin {
            builder.add(.allowSetPIN1)
        }
        if allowSwapPin2 {
            builder.add(.allowSetPIN2)
        }
        if useCvc {
            builder.add(.useCvc)
        }
        if isReusable {
            builder.add(.isReusable)
        }
        if useOneCommandAtTime {
            builder.add(.useOneCommandAtTime)
        }
        if useNdef {
            builder.add(.useNDEF)
        }
        if useDynamicNdef {
            builder.add(.useDynamicNDEF)
        }
        if disablePrecomputedNdef {
            builder.add(.disablePrecomputedNDEF)
        }
        if protocolAllowUnencrypted {
            builder.add(.allowUnencrypted)
        }
        if protocolAllowStaticEncryption {
            builder.add(.allowFastEncryption)
        }
        if forbidDefaultPin {
            builder.add(.prohibitDefaultPIN1)
        }
        if useActivation {
            builder.add(.useActivation)
        }
        if useBlock {
            builder.add(.useBlock)
        }
        if smartSecurityDelay {
            builder.add(.smartSecurityDelay)
        }
        if protectIssuerDataAgainstReplay {
            builder.add(.protectIssuerDataAgainstReplay)
        }
        if forbidPurgeWallet {
            builder.add(.prohibitPurgeWallet)
        }
        if allowSelectBlockchain {
            builder.add(.allowSelectBlockchain)
        }
        if skipCheckPIN2andCVCIfValidatedByIssuer {
            builder.add(.skipCheckPIN2CVCIfValidatedByIssuer)
        }
        if skipSecurityDelayIfValidatedByIssuer {
            builder.add(.skipSecurityDelayIfValidatedByIssuer)
        }
        if skipSecurityDelayIfValidatedByLinkedTerminal {
            builder.add(.skipSecurityDelayIfValidatedByLinkedTerminal)
        }
        if restrictOverwriteIssuerDataEx {
            builder.add(.restrictOverwriteIssuerExtraData)
        }
        if requireTerminalTxSignature {
            builder.add(.requireTermTxSignature)
        }
        if requireTerminalCertSignature {
            builder.add(.requireTermCertSignature)
        }
        if checkPin3onCard {
            builder.add(.checkPIN3OnCard)
        }
        return builder.build()
    }
    
    func createCardId() -> String? {
        guard let series = self.series else {
            return nil
        }
        
        if startNumber <= 0 || (series.count != 2 && series.count != 4) {
            return nil
        }
        
        if !checkSeries(series) {
            return nil
        }
        
        let tail = series.count == 2 ? String(format: "%013d", startNumber) : String(format: "%011d", startNumber)
        var cardId = (series + tail).replacingOccurrences(of: " ", with: "")
        
        guard let firstCidCharacter = cardId.first, let secondCidCharacter = cardId.dropFirst().first else {
            return nil
        }
        
        if cardId.count != 15 || !Alf.contains(firstCidCharacter) || !Alf.contains(secondCidCharacter) {
            return nil
        }
        
        cardId += "0"
        var sum: UInt32 = 0
        for i in 0..<cardId.count {
            // get digits in reverse order
            let index = cardId.index(cardId.endIndex, offsetBy: -i-1)
            let cDigit = cardId[index]
            let cDigitInt = cDigit.unicodeScalars.first!.value
            var digit = ("0"..."9").contains(cDigit) ?
                cDigitInt - UnicodeScalar("0").value
                : cDigitInt - UnicodeScalar("A").value
            
            // every 2nd number multiply with 2
            if i % 2 == 1 {
                digit *= 2
            }
            
            sum += digit > 9 ? digit - 9 : digit
        }
        let lunh = (10 - sum % 10) % 10
        return cardId[..<cardId.index(cardId.startIndex, offsetBy: 15)] + String(format: "%d", lunh)
    }
    
    private func checkSeries(_ series: String) -> Bool {
        let containsList = series.filter { Alf.contains($0) }
        return containsList.count == series.count
    }
}
