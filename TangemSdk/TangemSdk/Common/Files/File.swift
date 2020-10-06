//
//  File.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/6/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13, *)
public struct File: Codable {
	public init(fileIndex: Int, fileSettings: FileSettings?, fileData: Data) {
		self.fileIndex = fileIndex
		self.fileSettings = fileSettings
		self.fileData = fileData
	}
	
	public init(response: ReadFileDataResponse) {
		fileIndex = response.fileIndex
		fileSettings = response.fileSettings
		fileData = response.fileData
	}
	
	let fileIndex: Int
	let fileSettings: FileSettings?
	let fileData: Data
}
