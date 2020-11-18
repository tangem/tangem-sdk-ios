//
//  FirmwareVersion.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct FirmwareVersion: Codable {
	
	public static let zero = FirmwareVersion(major: 0, minor: 0)
	public static let max = FirmwareVersion(major: Int.max, minor: 0)
	
	public let version: String
	
	private(set) public var major: Int = 0
	private(set) public var minor: Int = 0
	private(set) public var hotFix: Int = 0
	private(set) public var type: CardType? = nil
	
	private(set) var versionStr: String = "0.0.0"
	
	var versionDouble: Double {
		Double("\(major).\(minor)")!
	}
	
	public init(version: String) {
		self.version = version
		
		let versionCleaned = version.remove("\0")
		
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
		
		versionStr = "\(major).\(minor).\(hotFix)"
		type = .type(for: cardTypeStr)
	}
	
	public init(major: Int, minor: Int, hotFix: Int = 0, type: CardType = .sdk) {
		self.major = major
		self.minor = minor
		self.hotFix = hotFix
		self.type = type
		
		var version = "\(major).\(minor)"
		versionStr = version + ".\(hotFix)"
		version += hotFix != 0 ? ".\(hotFix)" : ""
		version += type.rawValue
		
		self.version = version
	}
}

extension FirmwareVersion: Comparable {
	public static func < (lhs: FirmwareVersion, rhs: FirmwareVersion) -> Bool {
		return lhs.versionStr.compare(rhs.versionStr, options: .numeric) == .orderedAscending
	}

	public static func >= (lhs: FirmwareVersion, rhs: FirmwareVersion) -> Bool {
		let result = lhs.versionStr.compare(rhs.versionStr, options: .numeric)
		return result == .orderedDescending || result == .orderedSame
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
