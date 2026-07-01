//
//  OnlineAttestationResponse.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public struct OnlineAttestationResponse: Codable {
    public let manufacturerSignature: Data?
    public let issuerSignature: Data
}
