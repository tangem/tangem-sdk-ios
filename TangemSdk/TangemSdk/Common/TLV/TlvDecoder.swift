//
//  TlvDecoder.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
/// Decode value fields in `Tlv` from raw bytes to concrete types
/// according to their `TlvTag` and corresponding `TlvValueType`.
public final class TlvDecoder {
    let tlv: [Tlv]
    
    /// Initializer
    /// - Parameter tlv: array of TLVs, which values are to be converted to particular classes.
    public init(tlv: [Tlv]) {
        self.tlv = tlv
    }
    
    /**
     * Finds `Tlv` by its `TlvTag`.
     * Returns nil if `Tlv` is not found, otherwise converts its value to `T`.
     *
     * - Parameter tag: `TlvTag` of a `Tlv` which value is to be returned.
     *
     * - Returns: Value converted to an optional type `T`.
     */
    public func decodeOptional<T>(_ tag: TlvTag) throws -> T? {
        do {
            let decoded: T = try innerDecode(tag, asOptional: true)
            return decoded
        } catch TangemSdkError.decodingFailedMissingTag {
            return nil
        }
    }
    
    /**
     * Finds `Tlv` by its `TlvTag`.
     * Throws `TangemSdkError.decodingFailedMissingTag` if `Tlv` is not found,
     * otherwise converts `Tlv` value to `T`. Can throw  `TangemSdkError`
     *
     * - Parameter tag: `TlvTag` of a `Tlv` which value is to be returned.
     *
     * - Returns: Value converted to a type `T`.  You can use try? and decode to optional type `T?` without exception handling
     *
     */
    public func decode<T>(_ tag: TlvTag) throws -> T {
        return try innerDecode(tag, asOptional: false)
    }
    
    
    private func innerDecode<T>(_ tag: TlvTag, asOptional: Bool) throws -> T {
        guard let tagValue = tlv.value(for: tag) else {
            if tag.valueType == .boolValue {
                guard Bool.self == T.self || Bool?.self == T.self else {
                    print("Decoding error. Type for tag: \(tag) must be Bool")
                    throw TangemSdkError.decodingFailedTypeMismatch
                }
                
                return false as! T
            }
            if !asOptional {
                print("Decoding error. Missing tag: \(tag)")
            }
            
            throw TangemSdkError.decodingFailedMissingTag
        }
        
        switch tag.valueType {
        case .hexString:
            guard String.self == T.self || String?.self == T.self else {
                print("Decoding error. Type for tag: \(tag) must be String")
                throw TangemSdkError.decodingFailedTypeMismatch
            }
            
            let hexString = tagValue.asHexString()
            return hexString as! T
        case .utf8String:
            guard String.self == T.self || String?.self == T.self else {
                print("Decoding error. Type for tag: \(tag) must be String")
                throw TangemSdkError.decodingFailedTypeMismatch
            }
            
            guard let utfValue = tagValue.toUtf8String() else {
                print("Decoding error. Failed convert \(tag) to utf8 string")
                throw TangemSdkError.decodingFailed
            }
            
            return utfValue as! T
        case .intValue, .byte, .uint16:
            guard Int.self == T.self || Int?.self == T.self else {
                print("Decoding error. Type for tag: \(tag) must be Int")
                throw TangemSdkError.decodingFailedTypeMismatch
            }
            
            let intValue = tagValue.toInt()
            return intValue as! T
        case .data:
            guard Data.self == T.self || Data?.self == T.self else {
                print("Decoding error. Type for tag: \(tag) must be Data")
                throw TangemSdkError.decodingFailedTypeMismatch
            }
            
            return tagValue as! T
        case .ellipticCurve:
            guard EllipticCurve.self == T.self || EllipticCurve?.self == T.self else {
                print("Decoding error. Type for tag: \(tag) must be EllipticCurve")
                throw TangemSdkError.decodingFailedTypeMismatch
            }
            
            guard let utfValue = tagValue.toUtf8String(),
                let curve = EllipticCurve(rawValue: utfValue) else {
                    print("Decoding error. Failed convert \(tag) to utfValue and curve")
                    throw TangemSdkError.decodingFailed
            }
            
            return curve as! T
        case .boolValue:
            guard Bool.self == T.self || Bool?.self == T.self else {
                print("Decoding error. Type for tag: \(tag) must be Bool")
                throw TangemSdkError.decodingFailedTypeMismatch
            }
            
            return true as! T
        case .dateTime:
            guard Date.self == T.self || Date?.self == T.self else {
                print("Decoding error. Type for tag: \(tag) must be Date")
                throw TangemSdkError.decodingFailedTypeMismatch
            }
            
            guard let date = tagValue.toDate() else {
                print("Decoding error. Failed convert \(tag) to date")
                throw TangemSdkError.decodingFailed
            }
            
            return date as! T
            
        case .productMask:
            guard ProductMask.self == T.self || ProductMask?.self == T.self else {
                print("Decoding error. Type for tag: \(tag) must be ProductMask")
                throw TangemSdkError.decodingFailedTypeMismatch
            }
            
            guard let byte = tagValue.toBytes.first else {
                    print("Decoding error. Failed convert \(tag) to ProductMask")
                    throw TangemSdkError.decodingFailed
            }
            let productMask = ProductMask(rawValue: byte)
            return productMask as! T
        case .settingsMask:
            guard SettingsMask.self == T.self || SettingsMask?.self == T.self else {
                print("Decoding error. Type for tag: \(tag) must be SettingsMask")
                throw TangemSdkError.decodingFailedTypeMismatch
            }
            
            let intValue = tagValue.toInt()
            let settingsMask = SettingsMask(rawValue: intValue)
            return settingsMask as! T
        case .cardStatus:
            guard CardStatus.self == T.self || CardStatus?.self == T.self else {
                print("Decoding error. Type for tag: \(tag) must be CardStatus")
                throw TangemSdkError.decodingFailedTypeMismatch
            }
            let intValue = tagValue.toInt()
            guard let cardStatus = CardStatus(rawValue: intValue) else {
                print("Decoding error. Failed convert \(tag) to int and CardStatus")
                throw TangemSdkError.decodingFailed
            }
            
            return cardStatus as! T
        case .signingMethod:
            guard SigningMethod.self == T.self || SigningMethod?.self == T.self else {
                print("Decoding error. Type for tag: \(tag) must be SigningMethod")
                throw TangemSdkError.decodingFailedTypeMismatch
            }
            
            let intValue = tagValue.toInt()
            let signingMethod = SigningMethod(rawValue: intValue)
            return signingMethod as! T
        case .issuerExtraDataMode:
            guard IssuerExtraDataMode.self == T.self || IssuerExtraDataMode?.self == T.self else {
                print("Decoding error. Type for tag: \(tag) must be IssuerExtraDataMode")
                throw TangemSdkError.decodingFailedTypeMismatch
            }
            
            guard let byte = tagValue.toBytes.first,
                let mode = IssuerExtraDataMode(rawValue: byte) else {
                    print("Decoding error. Failed convert \(tag) to IssuerExtraDataMode")
                    throw TangemSdkError.decodingFailed
            }
            
            return mode as! T
        }
    }
}
