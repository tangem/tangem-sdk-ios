//
//  FileSignatureGenerator.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/9/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct FileSignatureGenerator {
	static func generateStartingSignature(forCardWith cardId: String, data: Data, fileCounter: Int) -> Data {
		Data(hexString: cardId) + fileCounter.bytes4 + data.count.bytes2
	}
	
	static func generateFinalizingSignature(forCardWith cardId: String, data: Data, fileCounter: Int) -> Data {
		Data(hexString: cardId) + data + fileCounter.bytes4
	}
}
