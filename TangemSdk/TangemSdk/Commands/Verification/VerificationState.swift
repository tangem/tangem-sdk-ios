//
//  VerificationState.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

//todo: use for attestation?
public enum VerificationState: String, Codable, JSONStringConvertible {
    case passed
    case offline
    case failed
    case notVerified
    case cancelled
}
