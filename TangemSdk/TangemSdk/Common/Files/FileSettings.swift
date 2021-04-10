//
//  FileSettings.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public enum FileSettings: Int, Codable {
	case `public` = 0x0001, `private` = 0x0000
}

public struct FileSettingsChange {
    let fileIndex: Int
    let settings: FileSettings
    
    public init(fileIndex: Int, settings: FileSettings) {
        self.fileIndex = fileIndex
        self.settings = settings
    }
}
