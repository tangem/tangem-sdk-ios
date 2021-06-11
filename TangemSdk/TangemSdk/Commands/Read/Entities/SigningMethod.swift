//
//  SigningMethod.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Determines which type of data is required for signing.
public struct SigningMethod: OptionSet {
	public let rawValue: Byte
	
	public init(rawValue: Byte) {
		if rawValue & 0x80 != 0 {
			self.rawValue = rawValue
		} else {
			self.rawValue = 0b10000000|(1 << rawValue)
		}
	}
}

extension SigningMethod: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(toStringArray())
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        let stringValues = try values.decode([String].self)
        var mask = SigningMethod()
        
        for item in Method.allCases {
            if stringValues.contains(item.rawValue.capitalizingFirst()) {
                mask.update(with: item.value)
            }
        }
        
        self = mask
    }
}

//MARK: - Constants
extension SigningMethod {
    public static let signHash = SigningMethod(rawValue: 0b10000000|(1 << 0))
    public static let signRaw = SigningMethod(rawValue: 0b10000000|(1 << 1)) //todo: dv
    public static let signHashSignedByIssuer = SigningMethod(rawValue: 0b10000000|(1 << 2))
    public static let signRawSignedByIssuer = SigningMethod(rawValue: 0b10000000|(1 << 3)) //todo: dv
    public static let signHashSignedByIssuerAndUpdateIssuerData = SigningMethod(rawValue: 0b10000000|(1 << 4)) //todo: remove
    public static let signRawSignedByIssuerAndUpdateIssuerData = SigningMethod(rawValue: 0b10000000|(1 << 5)) //todo: remove
    public static let signPos = SigningMethod(rawValue: 0b10000000|(1 << 6)) //todo: remove
}

extension SigningMethod {
    private enum Method: String, CaseIterable {
        case signHash
        case signRaw
        case signHashSignedByIssuer
        case signRawSignedByIssuer
        case signHashSignedByIssuerAndUpdateIssuerData
        case signRawSignedByIssuerAndUpdateIssuerData
        case signPos
        
        var value: SigningMethod {
            switch self {
            case .signHash:
                return .signHash
            case .signRaw:
                return .signRaw
            case .signHashSignedByIssuer:
                return .signHashSignedByIssuer
            case .signRawSignedByIssuer:
                return .signRawSignedByIssuer
            case .signHashSignedByIssuerAndUpdateIssuerData:
                return .signHashSignedByIssuerAndUpdateIssuerData
            case .signRawSignedByIssuerAndUpdateIssuerData:
                return .signRawSignedByIssuerAndUpdateIssuerData
            case .signPos:
                return .signPos
            }
        }
    }
}

extension SigningMethod: StringArrayConvertible {
    func toStringArray() -> [String] {
        var values = [String]()
        
        for item in Method.allCases {
            if contains(item.value) {
                values.append(item.rawValue.capitalizingFirst())
            }
        }
        
        return values
    }
}

extension SigningMethod: LogStringConvertible, JSONStringConvertible {}
