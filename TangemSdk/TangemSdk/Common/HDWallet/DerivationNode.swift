//
//  DerivationNode.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public enum DerivationNode: Equatable {
    case hardened(Int)
    case notHardened(Int)
    
    var pathDescription: String {
        switch self {
        case .hardened(let index):
            return "\(index)\(DerivationPath.Constants.hardenedSymbol)"
        case .notHardened(let index):
            return "\(index)"
        }
    }
}

extension DerivationNode {
    func serialize() -> Data {
        switch self {
        case .hardened(let index):
            let hardenedIndex = index + Constants.hardenedOffset
            return hardenedIndex.bytes4
        case .notHardened(let index):
            return index.bytes4
        }
    }
    
    static func deserialize(from data: Data) -> DerivationNode {
        let index = data.toInt()
        if index >= Constants.hardenedOffset {
            return .hardened(index - Constants.hardenedOffset)
        }
        
        return .notHardened(index)
    }
}

private extension DerivationNode {
    enum Constants {
        static let hardenedOffset: Int = .init(0x80000000)
    }
}
