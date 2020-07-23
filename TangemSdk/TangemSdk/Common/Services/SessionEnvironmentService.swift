//
//  SessionEnvironmentService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation


@available(iOS 13.0, *)
public class SessionEnvironmentService {
    let config: Config
    let terminalKeysService: TerminalKeysService
    let cardValuesStorage: CardValuesStorage
    
    var pin1: PinCode? = nil
    var pin2: PinCode? = nil
    
    init(config: Config, terminalKeysService: TerminalKeysService, cardValuesStorage: CardValuesStorage) {
        self.config = config
        self.terminalKeysService = terminalKeysService
        self.cardValuesStorage = cardValuesStorage
    }
    
    func createEnvironment(cardId: String?) -> SessionEnvironment {
        var environment = SessionEnvironment()
        environment.legacyMode = config.legacyMode ?? NfcUtils.isPoorNfcQualityDevice
        if config.linkedTerminal ?? !NfcUtils.isPoorNfcQualityDevice {
            environment.terminalKeys = terminalKeysService.getKeys()
        }
        environment.allowedCardTypes = config.allowedCardTypes
        environment.handleErrors = config.handleErrors
        
        var pin1: PinCode? = self.pin1 ?? TangemSdk.pin1
        var pin2: PinCode? = self.pin2
        
        if let cid = cardId, let resolvedPin2 = TangemSdk.pins2[cid] {
            pin2 = resolvedPin2
        }
        
        if let cid = cardId, let cardValues = cardValuesStorage.getValues(for: cid) {
            environment.cardValidation =  cardValues.cardValidation
            environment.cardVerification = cardValues.cardVerification
            environment.codeVerification = cardValues.codeVerification
            
            if pin1 == nil && cardValues.isPin1Default {
                pin1 = PinCode(.pin1)
            }
            
            if pin2 == nil && cardValues.isPin2Default {
                pin2 = PinCode(.pin2)
            }
        }
        
        environment.pin1 = pin1 ?? PinCode(.pin1)
        environment.pin2 = pin2 ?? PinCode(.pin2)
        return environment
    }
    
    func updateEnvironment(_ environment: SessionEnvironment, for cardId: String) -> SessionEnvironment {
        guard let cardValues = cardValuesStorage.getValues(for: cardId.uppercased()) else {
            return environment
        }
        
        var newEnvironment = environment
        newEnvironment.cardVerification = cardValues.codeVerification ?? .notVerified
        newEnvironment.cardValidation = cardValues.cardValidation ?? .notVerified
        newEnvironment.codeVerification = cardValues.codeVerification ?? .notVerified
        
        if newEnvironment.pin1.isDefault && !cardValues.isPin1Default {
            newEnvironment.pin1 = PinCode(.pin1, value: nil)
        }
        
        if newEnvironment.pin2.isDefault && !cardValues.isPin2Default {
            newEnvironment.pin2 = PinCode(.pin2, value: nil)
        }
        
        return newEnvironment
    }
    
    func saveEnvironmentValues(_ environment: SessionEnvironment, cardId: String?) {
        if config.savePin1InStaticField {
            TangemSdk.pin1 = environment.pin1
        }
        
        guard let cid = cardId else {
            return
        }
        
        if config.savePin2InStaticField {
            TangemSdk.pins2[cid] = environment.pin2
        }
        
        cardValuesStorage.saveValues(cardId: cid.uppercased(),
                                     isPin1Default: environment.pin1.isDefault,
                                     isPin2Default: environment.pin2.isDefault,
                                     cardVerification: environment.cardVerification,
                                     cardValidation: environment.cardValidation,
                                     codeVerification: environment.codeVerification)
}
}
