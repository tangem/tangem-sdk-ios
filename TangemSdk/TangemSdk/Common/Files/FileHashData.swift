//
//  FileHashData.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/20/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct FileHashData: Codable {
	public let startingHash: Data
	public let finalizingHash: Data
	
	public var startingSignature: Data?
	public var finalizingSignature: Data?
	
	public init(startingHash: Data, startingSignature: Data?, finalizingHash: Data, finalizingSignature: Data?) {
		self.startingHash = startingHash
		self.startingSignature = startingSignature
		self.finalizingHash = finalizingHash
		self.finalizingSignature = finalizingSignature
	}
}
