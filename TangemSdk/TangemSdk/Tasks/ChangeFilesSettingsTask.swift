//
//  ChangeFilesSettingsTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
public final class ChangeFilesSettingsTask: CardSessionRunnable {
	public typealias CommandResponse = SimpleResponse
	
	public init(files: [File]) {
		self.files = files
	}
	
	public var requiresPin2: Bool { true }
	
	private var files: [File]
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<SimpleResponse>) {
		changeFileSettings(session: session, completion: completion)
	}
	
	private func changeFileSettings(session: CardSession, completion: @escaping CompletionResult<SimpleResponse>) {
		guard let file = files.popLast() else {
			completion(.success(SimpleResponse(cardId: session.environment.card?.cardId ?? "")))
			return
		}
		let command = ChangeFileSettingsCommand(fileIndex: file.fileIndex, newSettings: file.fileSettings ?? .public)
		command.run(in: session) { (result) in
			switch result {
			case .success:
				self.changeFileSettings(session: session, completion: completion)
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
}
