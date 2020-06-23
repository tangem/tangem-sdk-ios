//
//  NdefRecord.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 22.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct NdefRecord {
    enum NdefRecordType {
        case uri
        case aar
        case text
    }
    
    let type: NdefRecordType
    let value: String
    
    func toBytes() -> Data? {
        return value.data(using: .utf8)
    }
}
