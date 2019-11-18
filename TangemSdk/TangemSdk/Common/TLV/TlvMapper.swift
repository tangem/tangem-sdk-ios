//
//  TlvMapper.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

enum TlvMapperError: Error {
    case missingTag
    case wrongType
    case convertError
}

/// Maps value fields in `Tlv` from raw bytes to concrete classes
/// according to their `TlvTag` and corresponding `TlvValueType`.
public final class TlvMapper {
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
    public func mapOptional<T>(_ tag: TlvTag) throws -> T? {
        do {
            let mapped: T = try innerMap(tag, asOptional: true)
            return mapped
        } catch TlvMapperError.missingTag {
            return nil
        }
    }

    /**
     * Finds `Tlv` by its `TlvTag`.
     * Throws `TlvMapperError.missingTag` if `Tlv` is not found,
     * otherwise converts `Tlv` value to `T`. Can throw any of a `TlvMapperError`
     *
     * - Parameter tag: `TlvTag` of a `Tlv` which value is to be returned.
     *
     * - Returns: Value converted to a type `T`.  You can use try? and map to optional type `T?` without exception handling
     *
     */
    public func map<T>(_ tag: TlvTag) throws -> T {
        return try innerMap(tag, asOptional: false)
    }
    
    
    private func innerMap<T>(_ tag: TlvTag, asOptional: Bool) throws -> T {
        guard let tagValue = tlv.value(for: tag) else {
            if tag.valueType == .boolValue {
                guard Bool.self == T.self || Bool?.self == T.self else {
                    print("Mapping error. Type for tag: \(tag) must be Bool")
                    throw TlvMapperError.wrongType
                }
                
                return false as! T
            }
            if !asOptional {
                print("Mapping error. Missing tag: \(tag)")
            }
            
            throw TlvMapperError.missingTag
        }
        
        switch tag.valueType {
        case .hexString:
            guard String.self == T.self || String?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be String")
                throw TlvMapperError.wrongType
            }
            
            let hexString = tagValue.toHexString()
            return hexString as! T
        case .utf8String:
            guard String.self == T.self || String?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be String")
                throw TlvMapperError.wrongType
            }
            
            guard let utfValue = tagValue.toUtf8String() else {
                print("Mapping error. Failed convert \(tag) to utf8 string")
                throw TlvMapperError.convertError
            }
            
            return utfValue as! T
        case .intValue:
            guard Int.self == T.self || Int?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be Int")
                throw TlvMapperError.wrongType
            }
            
            let intValue = tagValue.toInt()
            return intValue as! T
        case .data:
            guard Data.self == T.self || Data?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be Data")
                throw TlvMapperError.wrongType
            }
            
            return tagValue as! T
        case .ellipticCurve:
            guard EllipticCurve.self == T.self || EllipticCurve?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be EllipticCurve")
                throw TlvMapperError.wrongType
            }
            
            guard let utfValue = tagValue.toUtf8String(),
                let curve = EllipticCurve(rawValue: utfValue) else {
                    print("Mapping error. Failed convert \(tag) to utfValue and curve")
                    throw TlvMapperError.convertError
            }
            
            return curve as! T
        case .boolValue:
            guard Bool.self == T.self || Bool?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be Bool")
                throw TlvMapperError.wrongType
            }
            
            return true as! T
        case .dateTime:
            guard Date.self == T.self || Date?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be Date")
                throw TlvMapperError.wrongType
            }

            guard let date = tagValue.toDate() else {
                print("Mapping error. Failed convert \(tag) to date")
                throw TlvMapperError.convertError
            }
            
            return date as! T
            
        case .productMask:
            guard ProductMask.self == T.self || ProductMask?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be ProductMask")
                throw TlvMapperError.wrongType
            }
            
            guard let byte = tagValue.bytes.first,
                let productMask = ProductMask(rawValue: byte) else {
                    print("Mapping error. Failed convert \(tag) to ProductMask")
                    throw TlvMapperError.convertError
            }
            
            return productMask as! T
        case .settingsMask:
            guard SettingsMask.self == T.self || SettingsMask?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be SettingsMask")
                throw TlvMapperError.wrongType
            }
            
            let intValue = tagValue.toInt()
            let settingsMask = SettingsMask(rawValue: intValue)
            return settingsMask as! T
        case .cardStatus:
            guard CardStatus.self == T.self || CardStatus?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be CardStatus")
                throw TlvMapperError.wrongType
            }
            let intValue = tagValue.toInt()
            guard let cardStatus = CardStatus(rawValue: intValue) else {
                    print("Mapping error. Failed convert \(tag) to int and CardStatus")
                    throw TlvMapperError.convertError
            }
            
            return cardStatus as! T
        case .signingMethod:
            guard SigningMethod.self == T.self || SigningMethod?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be SigningMethod")
                throw TlvMapperError.wrongType
            }
            
            let intValue = tagValue.toInt()
            let signingMethod = SigningMethod(rawValue: intValue)
            return signingMethod as! T
        }
    }
}
