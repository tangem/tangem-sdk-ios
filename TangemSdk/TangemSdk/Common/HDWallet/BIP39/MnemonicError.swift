//
//  MnemonicError.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum MnemonicError: Error {
    case invalidEntropyLength
    case invalidWordCount
    case invalidWordsFile
    case mnenmonicCreationFailed
}
