//
//  NdefRecord.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct NdefRecord: Codable {
    enum NdefRecordType: String, Codable {
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

extension NdefRecord {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let typeString = try values.decode(String.self, forKey: .type)
        if let type = NdefRecordType(rawValue: typeString.lowercased()) {
            self.type = type
        } else {
            throw TangemSdkError.decodingFailed("Failed to decode NdefRecordType")
        }
        value = try values.decode(String.self, forKey: .value)
    }
}
