//
//  MasterKeyFactory.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
protocol MasterKeyFactory {
    func makePrivateKey() throws -> ExtendedPrivateKey
}
