//
//  File.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/6/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13, *)
public class File: Codable, CustomStringConvertible {
	public init(fileIndex: Int, fileSettings: FileSettings?, fileData: Data) {
		self.fileIndex = fileIndex
		self.fileSettings = fileSettings
		self.fileData = fileData
	}
	
	init(response: ReadFileDataResponse) {
		fileIndex = response.fileIndex
		fileSettings = response.fileSettings
		fileData = response.fileData
	}
	
	internal static let emptyFile = File(fileIndex: 0, fileSettings: nil, fileData: Data())
	
	public let fileIndex: Int
	public let fileSettings: FileSettings?
	public let fileData: Data
	
	public var fileValidationStatus: FileValidation = .notValidated
	
	public var description: String {
		"File \(fileData) at index \(fileIndex) with settings: \(fileSettings) and validation statur: \(fileValidationStatus)"
	}
	
}

@available (iOS 13.0, *)
public enum FileValidation: String, Codable {
	case notValidated, valid, corrupted
}
