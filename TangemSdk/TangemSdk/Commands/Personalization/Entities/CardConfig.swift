//
//  CardConfig.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 22.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation


//“{\“issuerName\“:\“TANGEM SDK\“,\“acquirerName\“:\“Smart Cash\“,\“series\“:\“BB\“,\“startNumber\“:300000000000,\“count\“:0,\“pin\“:[145,180,209,66,130,63,125,32,197,240,141,246,145,34,222,67,243,95,5,122,152,141,150,25,246,211,19,132,133,201,162,3],\“pin2\“:[42,201,166,116,106,202,84,58,248,223,243,152,148,207,232,23,58,251,162,30,176,28,111,174,51,213,41,71,34,40,85,239],\“pin3\“:[227,176,196,66,152,252,28,20,154,251,244,200,153,111,185,36,39,174,65,228,100,155,147,76,164,149,153,27,120,82,184,85],\“hexCrExKey\“:\“00112233445566778899AABBCCDDEEFFFFEEDDCCBBAA998877665544332211000000111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFF\“,\“cvc\“:\“000\“,\“pauseBeforePin2\“:5000,\“smartSecurityDelay\“:true,\“curveID\“:\“secp256k1\“,\“signingMethods\“:{\“rawValue\“:0},\“maxSignatures\“:999999,\“isReusable\“:true,\“allowSetPIN1\“:null,\“allowSetPIN2\“:null,\“useActivation\“:false,\“useCvc\“:null,\“useNDEF\“:true,\“useDynamicNDEF\“:true,\“useOneCommandAtTime\“:false,\“useBlock\“:false,\“allowSelectBlockchain\“:false,\“prohibitPurgeWallet\“:null,\“allowUnencrypted\“:null,\“allowFastEncryption\“:null,\“protectIssuerDataAgainstReplay\“:false,\“prohibitDefaultPIN1\“:null,\“disablePrecomputedNDEF\“:false,\“skipSecurityDelayIfValidatedByIssuer\“:true,\“skipCheckPIN2CVCIfValidatedByIssuer\“:null,\“skipSecurityDelayIfValidatedByLinkedTerminal\“:true,\“restrictOverwriteIssuerExtraData\“:null,\“requireTerminalTxSignature\“:false,\“requireTerminalCertSignature\“:false,\“checkPIN3OnCard\“:null,\“createWallet\“:true,\“cardData\“:{\“issuerName\“:\“TANGEM SDK\“,\“batchId\“:\“FFFF\“,\“blockchainName\“:\“ETH\“,\“manufactureDateTime\“:\“2020-10-05\“,\“productMask\“:{\“rawValue\“:1}},\“ndefRecords\“:[{\“type\“:\“AAR\“,\“value\“:\“com.tangem.wallet\“},{\“type\“:\“URI\“,\“value\“:\“https://tangem.com\“}]}”


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
    let pin: Data
    let pin2: Data
    let pin3: Data
    let hexCrExKey: String?
    let cvc: String
    let pauseBeforePin2: Int
    let smartSecurityDelay: Bool
    let curveID: EllipticCurve
    let signingMethods: SigningMethod
    let maxSignatures: Int
    let isReusable: Bool
    let allowSetPIN1: Bool
    let allowSetPIN2: Bool
    let useActivation: Bool
    let useCvc: Bool
    let useNDEF: Bool
    let useDynamicNDEF: Bool
    let useOneCommandAtTime: Bool
    let useBlock: Bool
    let allowSelectBlockchain: Bool
    let prohibitPurgeWallet: Bool
    let allowUnencrypted: Bool
    let allowFastEncryption: Bool
    let protectIssuerDataAgainstReplay: Bool
    let prohibitDefaultPIN1: Bool
    let disablePrecomputedNDEF: Bool
    let skipSecurityDelayIfValidatedByIssuer: Bool
    let skipCheckPIN2CVCIfValidatedByIssuer: Bool
    let skipSecurityDelayIfValidatedByLinkedTerminal: Bool
    
    let restrictOverwriteIssuerExtraData: Bool
    
    let requireTerminalTxSignature: Bool
    let requireTerminalCertSignature: Bool
    let checkPIN3OnCard: Bool
    
    let createWallet: Bool
    
    let cardData: CardData
    let ndefRecords: [NdefRecord]
	
	let maxNumberOfWallets: Byte
    
    private let Alf = "ABCDEF0123456789"
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        issuerName = try values.decode(String.self, forKey: .issuerName)
        acquirerName = try values.decode(String.self, forKey: .acquirerName)
        series = try values.decode(String.self, forKey: .series)
        startNumber = try values.decode(Int64.self, forKey: .startNumber)
        count = try values.decode(Int.self, forKey: .count)
        pin = Data((try values.decode([Int].self, forKey: .pin)).map( { Byte($0) }))
        pin2 = Data((try values.decode([Int].self, forKey: .pin2)).map( { Byte($0) }))
        pin3 = Data((try values.decode([Int].self, forKey: .pin3)).map( { Byte($0) }))
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
        
        let signingMethodsDictionary = try values.decode([String:Byte].self, forKey: .signingMethods)
        if let rawValue = signingMethodsDictionary["rawValue"]  {
            signingMethods = SigningMethod(rawValue: rawValue)
        } else {
            throw TangemSdkError.decodingFailed
        }
        
        maxSignatures = try values.decode(Int.self, forKey: .maxSignatures)
        isReusable = try values.decode(Bool.self, forKey: .isReusable)
        allowSetPIN1 = try values.decode(Bool.self, forKey: .allowSetPIN1)
        allowSetPIN2 = try values.decode(Bool.self, forKey: .allowSetPIN2)
        useActivation = try values.decode(Bool.self, forKey: .useActivation)
        useCvc = try values.decode(Bool.self, forKey: .useCvc)
        useNDEF = try values.decode(Bool.self, forKey: .useNDEF)
        useDynamicNDEF = try values.decode(Bool.self, forKey: .useDynamicNDEF)
        useOneCommandAtTime = try values.decode(Bool.self, forKey: .useOneCommandAtTime)
        useBlock = try values.decode(Bool.self, forKey: .useBlock)
        allowSelectBlockchain = try values.decode(Bool.self, forKey: .allowSelectBlockchain)
        prohibitPurgeWallet = try values.decode(Bool.self, forKey: .prohibitPurgeWallet)
        allowUnencrypted = try values.decode(Bool.self, forKey: .allowUnencrypted)
        allowFastEncryption = try values.decode(Bool.self, forKey: .allowFastEncryption)
        protectIssuerDataAgainstReplay = try values.decode(Bool.self, forKey: .protectIssuerDataAgainstReplay)
        prohibitDefaultPIN1 = try values.decode(Bool.self, forKey: .prohibitDefaultPIN1)
        disablePrecomputedNDEF = try values.decode(Bool.self, forKey: .disablePrecomputedNDEF)
        skipSecurityDelayIfValidatedByIssuer = try values.decode(Bool.self, forKey: .skipSecurityDelayIfValidatedByIssuer)
        skipCheckPIN2CVCIfValidatedByIssuer = try values.decode(Bool.self, forKey: .skipCheckPIN2CVCIfValidatedByIssuer)
        skipSecurityDelayIfValidatedByLinkedTerminal = try values.decode(Bool.self, forKey: .skipSecurityDelayIfValidatedByLinkedTerminal)
        restrictOverwriteIssuerExtraData = try values.decode(Bool.self, forKey: .restrictOverwriteIssuerExtraData)
        requireTerminalTxSignature = try values.decode(Bool.self, forKey: .requireTerminalTxSignature)
        requireTerminalCertSignature = try values.decode(Bool.self, forKey: .requireTerminalCertSignature)
        checkPIN3OnCard = try values.decode(Bool.self, forKey: .checkPIN3OnCard)
        createWallet = try values.decode(Bool.self, forKey: .createWallet)
        cardData = try values.decode(CardData.self, forKey: .cardData)
        ndefRecords = try values.decode([NdefRecord].self, forKey: .ndefRecords)
		maxNumberOfWallets = try values.decode(Byte.self, forKey: .maxNumberOfWallets)
    }
    
    
    func createSettingsMask() -> SettingsMask {
        let builder = SettingsMaskBuilder()
        
        if allowSetPIN1 {
            builder.add(.allowSetPIN1)
        }
        if allowSetPIN2 {
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
        if useNDEF {
            builder.add(.useNDEF)
        }
        if useDynamicNDEF {
            builder.add(.useDynamicNDEF)
        }
        if disablePrecomputedNDEF {
            builder.add(.disablePrecomputedNDEF)
        }
        if allowUnencrypted {
            builder.add(.allowUnencrypted)
        }
        if allowFastEncryption {
            builder.add(.allowFastEncryption)
        }
        if prohibitDefaultPIN1 {
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
        if prohibitPurgeWallet {
            builder.add(.prohibitPurgeWallet)
        }
        if allowSelectBlockchain {
            builder.add(.allowSelectBlockchain)
        }
        if skipCheckPIN2CVCIfValidatedByIssuer {
            builder.add(.skipCheckPIN2CVCIfValidatedByIssuer)
        }
        if skipSecurityDelayIfValidatedByIssuer {
            builder.add(.skipSecurityDelayIfValidatedByIssuer)
        }
        if skipSecurityDelayIfValidatedByLinkedTerminal {
            builder.add(.skipSecurityDelayIfValidatedByLinkedTerminal)
        }
        if restrictOverwriteIssuerExtraData {
            builder.add(.restrictOverwriteIssuerExtraData)
        }
        if requireTerminalTxSignature {
            builder.add(.requireTermTxSignature)
        }
        if requireTerminalCertSignature {
            builder.add(.requireTermCertSignature)
        }
        if checkPIN3OnCard {
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
        
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = series.count == 2 ? 13 : 11
        guard let tail = formatter.string(from: NSNumber(value: startNumber)) else {
            return nil
        }
        
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
