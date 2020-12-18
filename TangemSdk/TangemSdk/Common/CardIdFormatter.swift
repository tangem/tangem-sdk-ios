//
//  CardIdFormatter.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct CardIdFormatter {
    public init() {}
    
    public func formatted(cid: String, numbers: Int? = nil) -> String {
        let format = "cid_format".localized
        let croppedCid = numbers == nil ? cid : String(cid.dropLast().suffix(numbers!))
        return String(format: format, croppedCid)
    }
}
