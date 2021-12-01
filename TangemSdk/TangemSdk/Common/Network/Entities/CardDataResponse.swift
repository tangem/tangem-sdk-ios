//
//  CardDataResponse.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public struct CardDataResponse: Codable {
    let manufacturerSignature: Data
    let issuerSignature: Data
}
