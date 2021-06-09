//
//  FirmwareVersion.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Holds information about card firmware version included version saved on card `version`,
/// splitted to `major`, `minor` and `hotFix` and `FirmwareType`
public struct FirmwareVersion: Codable, JSONStringConvertible {
	/// Version that saved on card
	public let stringValue: String
	
    public var doubleValue: Double {
        Double("\(major).\(minor)")!
    }
    
	private(set) public var major: Int = 0
	private(set) public var minor: Int = 0
	private(set) public var hotFix: Int = 0
	private(set) public var type: FirmwareType
	
	public init(stringValue: String) {
		self.stringValue = stringValue
		
		let versionCleaned = stringValue.remove("\0")
		
		let cardTypeStr = versionCleaned.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789."))
		let result = versionCleaned.remove(cardTypeStr)
		
		var splitted = result.split(separator: ".")
		if let majorStr = splitted.first, let major = Int(majorStr) {
			self.major = major
			splitted.removeFirst()
		}
		
		if let minorStr = splitted.first, let minor = Int(minorStr) {
			self.minor = minor
			splitted.removeFirst()
		}
		
		if let hotFixStr = splitted.first, let hotFix = Int(hotFixStr) {
			self.hotFix = hotFix
		}
		
		type = .type(for: cardTypeStr)
	}
	
	public init(major: Int, minor: Int, hotFix: Int = 0, type: FirmwareType = .sdk) {
		self.major = major
		self.minor = minor
		self.hotFix = hotFix
		self.type = type
		
		let hotFixSuffix = ".\(hotFix)"
		var version = "\(major).\(minor)"
		version += hotFix != 0 ? hotFixSuffix : ""
		version += type.rawValue
		
		self.stringValue = version
	}
}

extension FirmwareVersion: Comparable {
	public static func < (lhs: FirmwareVersion, rhs: FirmwareVersion) -> Bool {
		if lhs.major != rhs.major {
			return lhs.major < rhs.major
		} else if lhs.minor != rhs.minor {
			return lhs.minor < rhs.minor
		} else {
			return lhs.hotFix < rhs.hotFix
		}
	}
	
	public static func == (lhs: FirmwareVersion, rhs: FirmwareVersion) -> Bool {
		lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.hotFix == rhs.hotFix
	}
	
	public static func >= (lhs: FirmwareVersion, rhs: FirmwareVersion) -> Bool {
		if lhs.major != rhs.major {
			return lhs.major > rhs.major
		} else if lhs.minor != rhs.minor {
			return lhs.minor > rhs.minor
		} else {
			return lhs.hotFix >= rhs.hotFix
		}
	}
	
	public static func < (lhs: FirmwareVersion?, rhs: FirmwareVersion) -> Bool {
		guard let lhs = lhs else { return false }
		
		return lhs < rhs
	}
	
	public static func >= (lhs: FirmwareVersion?, rhs: FirmwareVersion) -> Bool {
		guard let lhs = lhs else { return false }
		
		return lhs >= rhs
	}
	
}
//MARK: - Constants
extension FirmwareVersion {
    /// Multi-wallet
    public static let multiwalletAvailable = FirmwareVersion(major: 4, minor: 0)
    /// Field on card that describes is pin2 is default value or not
    public static let pin2IsDefaultAvailable = FirmwareVersion(major: 4, minor: 1)
    /// Read-write files
    public static let filesAvailable = FirmwareVersion(major: 3, minor: 29)
    
    public static let min = FirmwareVersion(major: 0, minor: 0)
    public static let max = FirmwareVersion(major: Int.max, minor: 0)
}

extension FirmwareVersion {
    public enum FirmwareType: String, Codable, CaseIterable, JSONStringConvertible {
        case sdk = "d SDK"
        case release = "r"
        case special
        
        static func type(for str: String) -> FirmwareType {
            FirmwareType(rawValue: str) ?? .special
        }
    }
}
