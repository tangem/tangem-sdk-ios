//
//  ManufacturerKey.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 28/03/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum ManufacturerKey: String, CaseIterable {
    case tangem = "TANGEM"
    case smartCash = "SMART CASH"

    var key: String {
        switch self {
        case .tangem:
            return "02630EC6371DA464986F51346B64E6A9711C530B1DD5FC3A145414373C231F7862"
        case .smartCash:
            return "042EDE119BF337B264FDA132CFC7C177824D3617DAC80F25DBB2A4A8A1183C03B9152305F8F1DB97004518480D5091ADC1CAB9EACCC18E1B9E9C3BEFB293DD37B2"
        }
    }

    var keyData: Data {
        Data(hexString: key)
    }

    var manufacturerName: String {
        rawValue
    }
}
