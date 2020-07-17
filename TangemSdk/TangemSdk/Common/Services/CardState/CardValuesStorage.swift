//
//  CardValuesStorage.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

class CardValuesStorage {
    let storageService: StorageService
    
    init(storageService: StorageService) {
        self.storageService = storageService
    }
    
    func saveValues(cardId: String,
                    isPin1Default: Bool,
                    isPin2Default: Bool,
                    cardVerification: VerificationState?,
                    cardValidation: VerificationState?,
                    codeVerification: VerificationState?) {
        
        let valuesObject = CardValues(isPin1Default: isPin1Default,
                                      isPin2Default: isPin2Default,
                                      cardVerification: cardVerification,
                                      cardValidation: cardValidation,
                                      codeVerification: codeVerification)
        
        storageService.set(object: valuesObject, forKey: .cardValues)
    }
    
    func getValues(for cardId: String) ->  CardValues? {
        return storageService.object(forKey: .cardValues)
    }
}
