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
        guard let numbers = numbers else{
            return cid
        }
        
        return String(cid.dropLast().suffix(numbers))
    }
}
