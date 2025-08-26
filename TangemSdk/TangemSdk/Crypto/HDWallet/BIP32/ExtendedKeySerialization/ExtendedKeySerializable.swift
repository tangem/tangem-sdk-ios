//
//  ExtendedKeySerializer.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#serialization-format
public protocol ExtendedKeySerializable {
    init(from extendedKeyString: String, networkType: NetworkType) throws
    func serialize(for networkType: NetworkType) throws -> String
}
