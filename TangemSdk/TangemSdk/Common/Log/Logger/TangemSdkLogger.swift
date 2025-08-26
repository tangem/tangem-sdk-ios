//
//  TangemSdkLogger.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public protocol TangemSdkLogger {
    func log(_ message: String, level: Log.Level)
}
