//
//  TlvBuilder.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public class TlvBuilder {
    private var tlvs = [Tlv]()
    private let encoder = TlvEncoder()
	
	private var loggingValues: [Any] = []
	private let isWithLogging = false
    
    public init() {}
    
    @discardableResult
    public func append<T>(_ tag: TlvTag, value: T?) throws -> TlvBuilder {
        tlvs.append(try encoder.encode(tag, value: value))
		if isWithLogging {
			loggingValues.append(value ?? "nil")
		}
        return self
    }
    
    public func serialize() -> Data {
		if isWithLogging {
			print("\nTlvBuilder. Data for Command APDU:")
			for (tlv, value) in zip(tlvs, loggingValues) {
				var val: String = "\(value)"
				if let data = value as? Data {
					val = data.asHexString()
				} else {
					val += " --- \(tlv.value.asHexString())"
				}
				print("TAG_\(tlv.tag) [0x\(String(format: "%02x", tlv.tagRaw)):\(tlv.tag.valueType)]: " + val)
			}
			print("")
		}
        return tlvs.serialize()
    }
}
