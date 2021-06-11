//
//  OptionSetCodable.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public protocol OptionKey: CaseIterable, RawRepresentable where RawValue == String {
    associatedtype SomeOptionSet: OptionSet
    
    var value: SomeOptionSet { get }
}

public protocol OptionSetCodable: Codable where Self: OptionSet {
    associatedtype OptionKeys: OptionKey
}

public extension OptionSetCodable where OptionKeys.SomeOptionSet == Element {
     func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        var values = [String]()
        
        for item in OptionKeys.allCases {
            if contains(item.value) {
                values.append(item.rawValue.capitalizingFirst())
            }
        }
        
        try container.encode(values)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        let stringValues = try values.decode([String].self)
        var optionSet = Self()
        
        for item in OptionKeys.allCases {
            if stringValues.contains(item.rawValue.capitalizingFirst()) {
                optionSet.update(with: item.value)
            }
        }
        
        self = optionSet
    }
}
