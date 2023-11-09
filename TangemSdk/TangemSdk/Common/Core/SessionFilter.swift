//
//  SessionFilter.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum SessionFilter {
    case cardId(String)
    case cardKitId(Data)
}

extension SessionFilter {
    init?(from cardId: String?) {
        guard let cardId else {
            return nil
        }

        self = .cardId(cardId)
    }
}
