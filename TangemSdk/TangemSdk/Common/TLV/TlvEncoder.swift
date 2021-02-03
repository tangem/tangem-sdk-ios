//
//  TlvEncoder.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public final class TlvEncoder {
    public func encode<T>(_ tag: TlvTag, value: T?) throws -> Tlv {
        do {
            if let value = value {
                return try Tlv(tag, value: encode(value, for: tag))
            } else {
                throw TangemSdkError.encodingFailed("Encoding error. Value for tag \(tag) is nil")
            }
        } catch {
            print(error)
            throw error
        }
    }
    
    private func encode<T>(_ value: T, for tag: TlvTag) throws -> Data {
        switch tag.valueType {
        case .hexString:
            try typeCheck(value, String.self, for: tag)
            return Data(hexString: value as! String)
        case .utf8String:
            try typeCheck(value, String.self, for: tag)
            let string = value as! String + "\0"
            if let data = string.data(using: .utf8) {
                return data
            } else {
                throw TangemSdkError.encodingFailed("Encoding error. Failed to convert string to utf8 Data")
            }
        case .byte:
            do {
                try typeCheck(value, Int.self, for: tag)
                return (value as! Int).byte
            } catch {
                try typeCheck(value, Byte.self, for: tag)
                return Data([(value as! Byte)])
            }
        case .intValue:
            try typeCheck(value, Int.self, for: tag)
            return (value as! Int).bytes4
        case .uint16:
            try typeCheck(value, Int.self, for: tag)
            return (value as! Int).bytes2
        case .boolValue:
            try typeCheck(value, Bool.self, for: tag)
            let value = value as! Bool
            return value ? Data([Byte(1)]) : Data([Byte(0)])
        case .data:
            try typeCheck(value, Data.self, for: tag)
            return value as! Data
        case .ellipticCurve:
            try typeCheck(value, EllipticCurve.self, for: tag)
            let curve = value as! EllipticCurve
            if let data = (curve.rawValue + "\0").data(using: .utf8) {
                return data
            } else {
                throw TangemSdkError.encodingFailed("Encoding error. Failed to convert EllipticCurve to utf8 Data")
            }
        case .dateTime:
            try typeCheck(value, Date.self, for: tag)
            let date = value as! Date
            let calendar = Calendar(identifier: .gregorian)
            let y = calendar.component(.year, from: date)
            let m = calendar.component(.month, from: date)
            let d = calendar.component(.day, from: date)
            return y.bytes2 + m.byte + d.byte
        case .productMask:
            try typeCheck(value, ProductMask.self, for: tag)
            let mask = value as! ProductMask
            return Data([mask.rawValue])
        case .settingsMask:
			do {
				try typeCheck(value, SettingsMask.self, for: tag)
				let mask = value as! SettingsMask
				let rawValue = mask.rawValue
				if 0xFFFF0000 & rawValue != 0 {
					 return rawValue.bytes4
				} else {
					 return rawValue.bytes2
				}
			} catch {
				print("Settings mask type is not Card settings mask. Trying to check WalletSettingsMask")
			}
			
			try typeCheck(value, WalletSettingsMask.self, for: tag)
			let mask = value as! WalletSettingsMask
			return mask.rawValue.bytes4
        case .cardStatus:
            try typeCheck(value, CardStatus.self, for: tag)
            let status = value as! CardStatus
            return status.rawValue.byte
        case .signingMethod:
            try typeCheck(value, SigningMethod.self, for: tag)
            let method = value as! SigningMethod
            return Data([method.rawValue])
        case .interactionMode:
			do {
				try typeCheck(value, IssuerExtraDataMode.self, for: tag)
				let mode = value as! IssuerExtraDataMode
				return Data([mode.rawValue])
			} catch {
				print("Interaction mode is not and issuer. Trying to check FileDataMode")
			}
			try typeCheck(value, FileDataMode.self, for: tag)
			let mode = value as! FileDataMode
			return Data([mode.rawValue])
		case .fileSettings:
			try typeCheck(value, FileSettings.self, for: tag)
			let settings = value as! FileSettings
			return settings.rawValue.bytes2
        }
    }
    
    private func typeCheck<FromType, ToType>(_ value: FromType, _ to: ToType, for tag: TlvTag) throws {
        guard type(of: value) is ToType else {
            throw TangemSdkError.encodingFailedTypeMismatch("Encoding error for tag: \(tag). Value is \(value) of type \(FromType.self). Expected: \(to).")
        }
    }
}
