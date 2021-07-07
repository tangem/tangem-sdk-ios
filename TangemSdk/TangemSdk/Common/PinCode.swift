//
//  PinCode.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

///// Contains information about pin code
public struct PinCode {
    let type: PinType
    let value: Data?
    
    var isDefault: Bool {
        return value == type.defaultValue
    }
    
    internal init(_ type: PinType) {
        self.value = type.defaultValue
        self.type = type
    }
    
    internal init(_ type: PinType, stringValue: String) {
        self.value = stringValue.sha256()
        self.type = type
    }
    
    internal init(_ type: PinType, value: Data?) {
        self.value = value
        self.type = type
    }
}

public extension PinCode {
    enum PinType {
        case pin1
        case pin2
        
        var defaultValue: Data {
            switch self {
            case .pin1:
                return PinCode.defaultPin1.sha256()
            case .pin2:
                return PinCode.defaultPin2.sha256()
            }
        }
    }
}

extension PinCode {
    private static let defaultPin1 = "000000"
    private static let defaultPin2 = "000"
}
