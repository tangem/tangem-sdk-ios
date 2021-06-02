//
//  VerificationState.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

//todo: do we actually need it?
public enum VerificationState: String, Codable, JSONStringConvertible {
    case passed
    case offline
    case failed
    case notVerified
    case cancelled
}
