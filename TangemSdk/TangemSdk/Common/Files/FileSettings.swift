//
//  FileSettings.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/6/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Available settings for files
@available(iOS 13.0, *)
public enum FileSettings: String, StringCodable, JSONStringConvertible {
    case `public`
    case `private`
    
    var intValue: Int {
        switch self {
        case .public:
            return 0x0001
        case .private:
            return 0x0000
        }
    }
    
    static func make(from intValue: Int) -> FileSettings? {
        if intValue == 0 {
            return .private
        } else if intValue == 1 {
            return .public
        }
        
        return nil
    }
}

/// Describes the new settings for the file by the specified index
@available(iOS 13.0, *)
public struct FileSettingsChange: Decodable {
    /// Index of file that will be updated
    let fileIndex: Int
    /// New settings for file
    let settings: FileSettings
    
    public init(fileIndex: Int, settings: FileSettings) {
        self.fileIndex = fileIndex
        self.settings = settings
    }
}
