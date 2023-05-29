//
//  BLSUtils.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 25.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

@available(iOS 13.0, *)
struct BLSUtils {
    /// hkdf_mod_r() implementaion (KeyGen)
    /// https://eips.ethereum.org/EIPS/eip-2333#hkdf_mod_r-1
    /// https://www.ietf.org/archive/id/draft-irtf-cfrg-bls-signature-05.html#name-keygen
    /// - Parameters:
    ///   - inputKeyMaterial: input keying material
    ///   - salt: salt value
    ///   - keyInfo: optional context and application specific information (can be a zero-length octet string)
    /// - Returns: Generated key
    func generateKey(inputKeyMaterial: Data, salt: Data = Constants.salt, keyInfo: Data? = nil) throws -> Data {
        let inputKeyMaterialData = inputKeyMaterial + Data([0x00])
        let prk = HKDFUtil<SHA256>.extract(inputKeyMaterial: inputKeyMaterialData, salt: salt)

        let info = keyInfo ?? Data() + Constants.count.bytes2
        let okm = HKDFUtil<SHA256>.expand(pseudoRandomKey: prk, info: info, outputByteCount: Constants.count)

        guard let intKey = BigInt(okm.hexString, radix: 16) else {
            throw BLSError.keyGenerationFailed
        }

        let sk  = intKey % Constants.curveOrder
        
        if sk != 0 {
            return Data(hexString: sk.hexString)
        }

        let salt = salt.getSha256()
        
        return try generateKey(inputKeyMaterial: inputKeyMaterial, salt: salt, keyInfo: keyInfo)
    }
}

@available(iOS 13.0, *)
extension BLSUtils {
    enum Constants {
        /// Version of  keygen algorithm prior to number 4
        static let saltPreV4: Data = "BLS-SIG-KEYGEN-SALT-".data(using: .utf8)!

        /// Actual version of  keygen algorithm
        static let salt: Data = saltPreV4.getSha256()
        
        /// l, Calculated as ceil((3 * ceil(log2(r))) / 16). where r is s the order of the BLS 12-381
        fileprivate static let count = 48

        /// r, defined in  https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-bls-signature-04
        fileprivate static let curveOrder = BigInt("52435875175126190479447740508185965837690552500527637822603658699938581184513", radix: 10)!
    }

    enum BLSError: Error {
        case keyGenerationFailed
    }
}
