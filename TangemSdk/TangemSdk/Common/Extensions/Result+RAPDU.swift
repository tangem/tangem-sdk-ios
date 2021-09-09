//
//  Result+RAPDU.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension Result where Success == ResponseApdu, Failure == TangemSdkError  {
    func getResponse() throws -> Success {
        switch self {
        case .success(let rapdu):
            return rapdu
        case .failure(let error):
            throw error
        }
    }
}
