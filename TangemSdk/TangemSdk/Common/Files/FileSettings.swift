//
//  FileSettings.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/6/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Available settings for files
public enum FileSettings: Byte, Codable {
	case `public` = 0x01, `private` = 0x00
}

/// Describes the new settings for the file by the specified index
public struct FileSettingsChange {
    /// Index of file that will be updated
    let fileIndex: Int
    /// New settings for file
    let settings: FileSettings
    
    public init(fileIndex: Int, settings: FileSettings) {
        self.fileIndex = fileIndex
        self.settings = settings
    }
}
