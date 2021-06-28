//
//  BatchIdFilter.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 28.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public enum BatchIdFilter {
    case allow(_ batches: [String])
    case deny(_ batches: [String])
    
    func isBatchIdAllowed(_ batchId: String) -> Bool {
        switch self {
        case .allow(let batches):
            return batches.contains(batchId)
        case .deny(let batches):
            return !batches.contains(batchId)
        }
    }
}
