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

/// This task allows to write multiple files to a card.
/// There are two secure ways to write files.
/// 1. Data can be signed by Issuer (the one specified on card during personalization) - `FileDataProtectedBySignature`.
/// 2. Data can be protected by Passcode (PIN2). `FileDataProtectedByPasscode` In this case,  Passcode (PIN2) is required for the command.
@available (iOS 13.0, *)
public final class WriteFilesTask: CardSessionRunnable {
	
	public var requiresPin2: Bool { _requiresPin2 }
	
	private let files: [DataToWrite]
	private let settings: Set<WriteFilesSettings>
		
	private var _requiresPin2: Bool = false
	private var currentFileIndex: Int = 0
	private var savedFilesIndices: [Int] = []
	
	public init(files: [DataToWrite], settings: Set<WriteFilesSettings> = [.overwriteAllFiles]) {
		self.files = files
		self.settings = settings
		files.forEach {
			let requiredPin2 = $0.requiredPin2
			if requiredPin2 {
				_requiresPin2 = requiredPin2
			}
		}
	}
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<WriteFilesResponse>) {
		guard files.count > 0 else {
			completion(.success(WriteFilesResponse(cardId: "", filesIndices: [])))
			return
		}
		if settings.contains(.overwriteAllFiles) {
			deleteFiles(session: session, completion: completion)
			return
		}
		writeFile(session: session, completion: completion)
	}
	
	private func deleteFiles(session: CardSession, completion: @escaping CompletionResult<WriteFilesResponse>) {
		let task = DeleteFilesTask(filesToDelete: nil)
		task.run(in: session) { (result) in
			switch result {
			case .success:
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
		WriteFileDataCommand(dataToWrite: files[currentFileIndex])
			.run(in: session) { (result) in
				switch result {
				case .success(let response):
					self.currentFileIndex += 1
					self.savedFilesIndices.append(response.fileIndex ?? 0)
					self.writeFile(session: session, completion: completion)
				case .failure(let error):
					completion(.failure(error))
				}
			}
	}
	
}
