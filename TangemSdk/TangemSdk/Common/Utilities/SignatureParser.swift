//
//  SignatureParser.swift
//  TangemSdk
//
//  Created by Andrew Son on 06/04/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

enum SignatureParser {
    private static let cardSingleSignatureSize = 64
    
    static func parseSignedSignature(_ signature: Data) throws -> [Data] {
        guard signature.count % cardSingleSignatureSize == 0 else {
            throw TangemSdkError.notValidSignedSignatureSize
        }
        
        var signatures = [Data]()
        let hashesCount = signature.count / cardSingleSignatureSize
        for index in 0..<hashesCount {
            let offsetMin = index * cardSingleSignatureSize
            let offsetMax = offsetMin + cardSingleSignatureSize
            
            let sig = signature[offsetMin..<offsetMax]
            
            signatures.append(sig)
        }
        
        return signatures
    }
}
