//
//  CardIdFormatter.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 18.12.2020.
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
