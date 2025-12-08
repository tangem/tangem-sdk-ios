//
//  TlvBuilder.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public class TlvBuilder {
    private var tlvs = [Tlv]()
    private let encoder = TlvEncoder()
    
    public init() {}
    
    @discardableResult
    public func append<T>(_ tag: TlvTag, value: T?) throws -> TlvBuilder {
        tlvs.append(try encoder.encode(tag, value: value))
        return self
    }

    @discardableResult
    func appendPinIfNeeded(_ tag: TlvTag, value: UserCode, card: Card?) throws -> TlvBuilder {
        switch tag {
        case .pin, .pin2:
            break
        default:
            throw TangemSdkError.encodingFailed("Wrong tag passed. Expected .pin or .pin2, got \(tag)")
        }

        if let card, card.firmwareVersion >= .isDefaultPinsOptional,
              value.value == value.type.defaultValue.getSHA256() {
            return self
        }

        tlvs.append(try encoder.encode(tag, value: value.value))
        return self
    }

    public func serialize() -> Data {
        return tlvs.serialize()
    }
}
