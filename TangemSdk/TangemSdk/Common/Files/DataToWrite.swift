//
//  DataToWrite.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/7/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
public struct DataToWrite {
	let data: Data
	var settings: Set<FileWriteSettings> = [.none]
	
	public init(data: Data, settings: Set<FileWriteSettings> = [.none]) {
		self.data = data
		self.settings = settings
	}
}
