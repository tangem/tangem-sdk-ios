//
//  MultiWalletTlvDecoder.swift
//  TangemSdk
//
//  Created by Andrew Son on 16/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public final class MultipleTlvDecoder: TlvDecoder {
    private let tlv: [Tlv]
    
    public init(tlv: [Tlv]) {
        self.tlv = tlv
    }
    
    func getTlv(for tag: TlvTag) -> Tlv? {
        tlv.first(where: { $0.tag == tag })
    }
    
    public func decodeMultiple<T>(_ tag: TlvTag) throws -> [T] {
        let tlvs = tlv.filter { $0.tag == tag }
        guard tlvs.count > 0 else {
            return []
        }
        
        return try tlvs.map {
            let decoded: T = try innerDecode(tag, tagValue: $0.value, asOptional: false)
            return decoded
        }
    }
}
