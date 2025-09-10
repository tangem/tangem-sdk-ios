//
//  CaseIterable+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

extension CaseIterable where Self: Equatable {
    func next() -> Self {
        let all = Self.allCases
        let selfIndex = all.firstIndex(of: self)!
        
        if selfIndex < all.endIndex {
            let nextIndex = all.index(after: selfIndex)
            return all[nextIndex]
        }
        
        return all[all.endIndex]
    }
}
