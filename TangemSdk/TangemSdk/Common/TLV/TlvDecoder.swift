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
            let decoded: T = try innerDecode(tag, tagValue: tlv.value(for: tag), asOptional: true)
            logTlv(tag, decoded)
            return decoded
        } catch TangemSdkError.decodingFailedMissingTag {
            return nil
        } catch {
            Log.error(error)
            throw error
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
        do {
            let decoded: T = try innerDecode(tag, tagValue: tlv.value(for: tag), asOptional: false)
            logTlv(tag, decoded)
            return decoded
        } catch {
            Log.error(error)
            throw error
        }
    }
    
    public func decodeArray<T>(_ tag: TlvTag) throws -> [T] {
        let tlvs = tlv.items(for: tag)
        guard tlvs.count > 0 else {
            return []
        }
        
        return try tlvs.map {
            let decoded: T = try innerDecode(tag, tagValue: $0.value, asOptional: false)
            return decoded
        }
    }
    
    func innerDecode<T>(_ tag: TlvTag, tagValue: Data?, asOptional: Bool) throws -> T {
        guard let tagValue = tagValue else {
            if tag.valueType == .boolValue {
                guard Bool.self == T.self || Bool?.self == T.self else {
                    throw TangemSdkError.decodingFailedTypeMismatch("Decoding error. Tag: \(tag). Type is \(T.self). Expected: \(Bool.self)")
                }
                
                return false as! T
            }
            
            throw TangemSdkError.decodingFailedMissingTag("Decoding error. Missing tag: \(tag)")
        }
        
        switch tag.valueType {
        case .hexString:
            try typeCheck(String.self, T.self, for: tag)
            let hexString = tagValue.asHexString()
            return hexString as! T
        case .utf8String:
            try typeCheck(String.self, T.self, for: tag)
            
            guard let utfValue = tagValue.toUtf8String() else {
                throw TangemSdkError.decodingFailed("Decoding error. Failed to convert \(tag) to utf8 string")
            }
            
            return utfValue as! T
        case .intValue, .byte, .uint16:
            try typeCheck(Int.self, T.self, for: tag)
            let intValue = tagValue.toInt()
            return intValue as! T
        case .data:
            try typeCheck(Data.self, T.self, for: tag)
            return tagValue as! T
        case .ellipticCurve:
            try typeCheck(EllipticCurve.self, T.self, for: tag)
            guard let utfValue = tagValue.toUtf8String(),
                  let curve = EllipticCurve(rawValue: utfValue) else {
                throw TangemSdkError.decodingFailed("Decoding error. Failed convert \(tag) to utfValue and curve")
            }
            
            return curve as! T
        case .boolValue:
            try typeCheck(Bool.self, T.self, for: tag)
            return true as! T
        case .dateTime:
            try typeCheck(Date.self, T.self, for: tag)
            guard let date = tagValue.toDate() else {
                throw TangemSdkError.decodingFailed("Decoding error. Failed convert \(tag) to date")
            }
            
            return date as! T
        case .productMask:
            try typeCheck(ProductMask.self, T.self, for: tag)
            guard let byte = tagValue.toBytes.first else {
                throw TangemSdkError.decodingFailed("Decoding error. Failed convert \(tag) to ProductMask")
            }
            
            let productMask = ProductMask(rawValue: byte)
            return productMask as! T
        case .settingsMask:
            try typeCheck(SettingsMask.self, T.self, for: tag)
            let intValue = tagValue.toInt()
            let settingsMask = SettingsMask(rawValue: intValue)
            return settingsMask as! T
        case .status:
            do {
                try typeCheck(CardStatus.self, T.self, for: tag)
                let intValue = tagValue.toInt()
                guard let cardStatus = CardStatus(rawValue: intValue) else {
                    throw TangemSdkError.decodingFailed("Decoding error. Failed convert \(tag) to int and CardStatus")
                }
                
                return cardStatus as! T
            } catch TangemSdkError.decodingFailedTypeMismatch {
                try typeCheck(WalletStatus.self, T.self, for: tag)
                let intValue = tagValue.toInt()
                guard let walletStatus = WalletStatus(rawValue: intValue) else {
                    throw TangemSdkError.decodingFailed("Decoding error. Failed convert \(tag) to int and WalletStatus")
                }
                return walletStatus as! T
            }
        case .signingMethod:
            try typeCheck(SigningMethod.self, T.self, for: tag)
            guard let byte = tagValue.toBytes.first else {
                throw TangemSdkError.decodingFailed("Decoding error. Failed convert \(tag) to SigningMethod")
            }
            
            let signingMethod = SigningMethod(rawValue: byte)
            return signingMethod as! T
        case .interactionMode:
            guard let byte = tagValue.toBytes.first else {
                throw TangemSdkError.decodingFailed("Decoding error. Failed convert \(tag) to InteractionMode")
            }
            
            if let mode = IssuerExtraDataMode(rawValue: byte)  {
                try typeCheck(IssuerExtraDataMode.self, T.self, for: tag)
                return mode as! T
            } else if let mode = FileDataMode(rawValue: byte) {
                try typeCheck(FileDataMode.self, T.self, for: tag)
                return mode as! T
            } else {
                throw TangemSdkError.decodingFailed("Decoding error. Unknown interaction mode")
            }
            
        case .fileSettings:
            try typeCheck(FileSettings.self, T.self, for: tag)
            let intValue = tagValue.toInt()
//            guard let fileSettings = FileSettings(rawValue: intValue) else {
//                throw TangemSdkError.notSupportedFileSettings
//            }
            
            let fileSettings = FileSettings(rawValue: 0x0001) 
            return fileSettings as! T
        }
    }
    
    private func typeCheck<T1, T2>(_ expected: T1.Type, _ current: T2.Type, for tag: TlvTag) throws {
        guard T2.self is T1.Type || T2.self is Optional<T1>.Type else {
            throw TangemSdkError.decodingFailedTypeMismatch("Decoding error. Tag: \(tag). Type is \(current). Expected: \(expected)")
        }
    }
    
    private func logTlv<T>(_ tag: TlvTag, _ value: T) {
        let tlvItem = tlv.item(for: tag) ?? Tlv(tag, value: Data(hexString: "00")) //dummy tlv for boolean values
        logTlv(tlvItem, value)
    }
}

extension TlvDecoder: TlvLogging { }
