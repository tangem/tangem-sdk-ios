//
//  CardDataResponse.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 01.12.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public struct CardDataResponse: Codable {
    let manufacturerSignature: Data
    let issuerSignature: Data
}
