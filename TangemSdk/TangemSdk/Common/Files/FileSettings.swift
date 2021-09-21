//
//  FileSettings.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/6/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

///// Available settings for files
//@available(iOS 13.0, *)
//public enum FileSettings: String, StringCodable, JSONStringConvertible {
//    case `public`
//    case `private`
//
//    var intValue: Int {
//        switch self {
//        case .public:
//            return 0x0001
//        case .private:
//            return 0x0000
//        }
//    }
//
//    static func make(from intValue: Int) -> FileSettings? {
//        if intValue == 0 {
//            return .private
//        } else if intValue == 1 {
//            return .public
//        }
//
//        return nil
//    }
//}

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


/// Determines which type of data is required for signing.
@available(iOS 13.0, *)
public struct FileSettings: OptionSet, OptionSetCustomStringConvertible {
    public let rawValue: Byte
    
    public init(rawValue: Byte) {
        if rawValue == 0 { //3.34 private by PIN2
            self.rawValue = 0x02
        } else {
            self.rawValue = rawValue
        }
    }
}

//MARK: - Constants
@available(iOS 13.0, *)
public extension FileSettings {
    static let readPublic = FileSettings(rawValue: 0x80)
    static let readAccessCode = FileSettings(rawValue: 0x01)
    static let readPasscode = FileSettings(rawValue: 0x02)
    static let readOwner = FileSettings(rawValue: 0x04)
    static let readLinkedTerminal = FileSettings(rawValue: 0x08)
    static let writePasscode = FileSettings(rawValue: 0x10)
    static let writeOwner = FileSettings(rawValue: 0x20)
    static let writeLinkedTerminal = FileSettings(rawValue: 0x40)
}

//MARK: - OptionSetCodable conformance
@available(iOS 13.0, *)
extension FileSettings: OptionSetCodable {
    public enum OptionKeys: String, OptionKey {
        case readPublic
        case readAccessCode
        case readPasscode
        case readOwner
        case readLinkedTerminal
        case writePasscode
        case writeOwner
        case writeLinkedTerminal
        
        public var value: FileSettings {
            switch self {
            case .readAccessCode:
                return .readAccessCode
            case .readLinkedTerminal:
                return .readLinkedTerminal
            case .readOwner:
                return .readOwner
            case .readPasscode:
                return .readPasscode
            case .readPublic:
                return .readPublic
            case .writeLinkedTerminal:
                return .writeLinkedTerminal
            case .writeOwner:
                return .writeOwner
            case .writePasscode:
                return .writePasscode
            }
        }
    }
}
