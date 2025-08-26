//
//  Error+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public extension Error {
    func toTangemSdkError() -> TangemSdkError {
        return TangemSdkError.parse(self)
    }
}
