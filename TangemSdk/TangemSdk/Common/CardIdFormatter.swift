//
//  CardIdFormatter.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 18.12.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Formatting CID in more readable manner
@available(iOS 13.0, *)
public struct CardIdFormatter {
    public init() {}
    
    public func crop(cardId: String, with length: Int? = nil) -> String {
        length == nil ? cardId : String(cardId.dropLast().suffix(length!))
    }
    
    public func formatted(cardId: String, numbers: Int? = nil) -> String {
        let croppedCardId = crop(cardId: cardId, with: numbers)
        let format = "cid_format".localized
        return String(format: format, croppedCardId)
    }
}
