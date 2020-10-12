//
//  DeleteFilesTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
public final class DeleteFilesTask: CardSessionRunnable {
	public typealias CommandResponse = SimpleResponse
	
	public init(filesToDelete: [File]) {
		print("Files to delete input", filesToDelete)
		self.filesToDelete = filesToDelete.sorted(by: { $0.fileIndex < $1.fileIndex })
		print("Sorted files to delete", self.filesToDelete)
	}
	
	public var requiresPin2: Bool { true }
	
	private var filesToDelete: [File]
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<SimpleResponse>) {
		deleteFile(session: session, completion: completion)
	}
	
	private func deleteFile(session: CardSession, completion: @escaping CompletionResult<SimpleResponse>) {
		guard let file = filesToDelete.popLast() else {
			completion(.success(SimpleResponse(cardId: session.environment.card?.cardId ?? "")))
			return
		}
		let command = DeleteFileCommand(fileAt: file.fileIndex)
		command.run(in: session) { (result) in
			switch result {
			case .success:
				self.deleteFile(session: session, completion: completion)
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
}
