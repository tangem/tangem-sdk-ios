//
//  NdefRecord.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
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
