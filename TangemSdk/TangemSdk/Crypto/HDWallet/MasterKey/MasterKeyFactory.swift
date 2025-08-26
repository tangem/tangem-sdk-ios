//
//  MasterKeyFactory.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol MasterKeyFactory {
    func makePrivateKey() throws -> ExtendedPrivateKey
}
