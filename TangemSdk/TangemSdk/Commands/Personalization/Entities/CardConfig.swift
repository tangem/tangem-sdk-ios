//
//  CardConfig.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 22.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation


/**
 * It is a configuration file with all the card settings that are written on the card
 * during [PersonalizeCommand].
 */
public struct CardConfig {
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
    let allowUnencrypted: Bool
    let allowFastEncryption: Bool
    let protectIssuerDataAgainstReplay: Bool
    let prohibitDefaultPIN1: Bool
    let disablePrecomputedNdef: Bool
    let skipSecurityDelayIfValidatedByIssuer: Bool
    let skipCheckPIN2CVCIfValidatedByIssuer: Bool
    let skipSecurityDelayIfletidatedByLinkedTerminal: Bool
    
    let restrictOverwriteIssuerExtraData: Bool
    
    let requireTerminalTxSignature: Bool
    let requireTerminalCertSignature: Bool
    let checkPin3onCard: Bool
    
    let createWallet: Bool
    
    let cardData: CardData
    let ndefRecords: [NdefRecord]
    
    private let Alf = "ABCDEF0123456789"
    
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
        if forbidPurgeWallet {
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
        if skipSecurityDelayIfletidatedByLinkedTerminal {
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
