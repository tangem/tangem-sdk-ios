//
//  PinCode.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Contains information about pin code
public struct PinCode {
    static let defaultPin1 = "000000"
    static let defaultPin2 = "000"
    
    public enum PinType {
        case pin1
        case pin2
    }
    
    let type: PinType
    let value: Data?
    
    var isDefault: Bool {
        switch type {
        case .pin1:
            return PinCode.defaultPin1.sha256() == value
        case .pin2:
            return PinCode.defaultPin2.sha256() == value
        }
    }

    internal init(_ type: PinType) {
        switch type {
        case .pin1:
            self.value = PinCode.defaultPin1.sha256()
        case .pin2:
            self.value = PinCode.defaultPin2.sha256()
        }
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
