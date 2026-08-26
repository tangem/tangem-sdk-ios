//
//  SuccessResponse.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public struct SuccessResponse: JSONStringConvertible {
    public let cardId: String

    public init(cardId: String) {
        self.cardId = cardId
    }
}
