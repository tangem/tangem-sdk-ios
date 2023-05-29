//
//  HKDFUtil.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 25.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import CommonCrypto

/// We can't use CryptoKit's HKDF because of iOS14
/// https://www.rfc-editor.org/rfc/rfc5869
@available(iOS 13.0, *)
enum HKDFUtil<H: HashFunction> {
    
    /// HKDF-Extract(salt, IKM) -> PRK
    /// - Parameters:
    ///   - inputKeyMaterial: input keying material
    ///   - salt: optional salt value (a non-secret random value); if not provided, it is set to a string of HashLen zeros.
    /// - Returns: a pseudorandom key (of HashLen octets)
    static func extract(inputKeyMaterial: Data, salt: Data? = nil) -> Data {
        let prk = HMAC<H>.authenticationCode(for: inputKeyMaterial, using: SymmetricKey(data: salt ?? Data()))
        return Data(prk)
    }
    
    /// HKDF-Expand(PRK, info, L) -> OKM
    /// - Parameters:
    ///   - pseudoRandomKey: a pseudorandom key of at least HashLen octets (usually, the output from the extract step)
    ///   - info: optional context and application specific information (can be a zero-length octet string)
    ///   - outputByteCount: length of output keying material in octets (<=255*HashLen)
    /// - Returns: output keying material (of L octets)
    static func expand(pseudoRandomKey: Data, info: Data? = nil, outputByteCount: Int) -> Data {
        let hashSize = H.Digest.byteCount
        let iterations = Int(ceil(Double(outputByteCount) / Double(hashSize)))
        
        var result = Data()
        result.reserveCapacity(iterations*hashSize)
        
        for iteration in 1...iterations {
            var hmac = HMAC<H>(key: SymmetricKey(data: pseudoRandomKey))
            hmac.update(data: result)
            hmac.update(data: info ?? Data())
            hmac.update(data: iteration.byte)
            let code = hmac.finalize()
            result.append(contentsOf: code)
        }
        
        return result.prefix(outputByteCount)
    }
}
