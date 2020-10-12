//
//  WriteFilesTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
public struct WriteFilesResponse: ResponseCodable {
	let cardId: String
	let filesIndices: [Int]
}

@available (iOS 13.0, *)
public enum WriteFilesSettings {
	case overwriteAllFiles
}

@available (iOS 13.0, *)
public final class WriteFilesTask: CardSessionRunnable {
	
	public init(files: [DataToWrite], settings: Set<WriteFilesSettings> = [.overwriteAllFiles], issuerKeys: KeyPair) {
		self.files = files
		self.issuerKeys = issuerKeys
		self.settings = settings
		files.forEach {
			let requiredPin2 = $0.settings.contains(.verifiedWithPin2)
			if requiredPin2 {
				_requiresPin2 = requiredPin2
			}
		}
	}
	
	public var requiresPin2: Bool { _requiresPin2 }
	
	private let files: [DataToWrite]
	private let issuerKeys: KeyPair
	private let settings: Set<WriteFilesSettings>
		
	private var _requiresPin2: Bool = false
	private var currentFileIndex: Int = 0
	private var fileDataCounter: Int?
	private var savedFilesIndices: [Int] = []
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<WriteFilesResponse>) {
		guard files.count > 0 else {
			completion(.success(WriteFilesResponse(cardId: "", filesIndices: [])))
			return
		}
		if settings.contains(.overwriteAllFiles) {
			deleteFiles(session: session, completion: completion)
			return
		}
		getFileCounter(session: session, completion: completion)
	}
	
	private func deleteFiles(session: CardSession, completion: @escaping CompletionResult<WriteFilesResponse>) {
		getFileCounter(session: session, completion: completion)
	}
	
	private func getFileCounter(session: CardSession, completion: @escaping CompletionResult<WriteFilesResponse>) {
		let read = ReadFileDataCommand(fileIndex: 0, readPrivateFiles: false)
		read.run(in: session) { (result) in
			switch result {
			case .success(let response):
				self.fileDataCounter = response.fileDataCounter
				self.writeFile(session: session, completion: completion)
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	private func writeFile(session: CardSession, completion: @escaping CompletionResult<WriteFilesResponse>) {
		guard
			let card = session.environment.card,
			let cardId = card.cardId
			else {
			completion(.failure(.cardError))
			return
		}
		guard currentFileIndex < files.count else {
			completion(.success(.init(cardId: cardId, filesIndices: savedFilesIndices)))
			return
		}
		let task = WriteFileDataTask(file: files[currentFileIndex], issuerKeys: issuerKeys, fileDataCounter: fileDataCounter)
		task.run(in: session) { (result) in
			switch result {
			case .success(let response):
				self.currentFileIndex += 1
				self.fileDataCounter? += 1
				self.savedFilesIndices.append(response.fileIndex ?? 0)
				self.writeFile(session: session, completion: completion)
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
}
