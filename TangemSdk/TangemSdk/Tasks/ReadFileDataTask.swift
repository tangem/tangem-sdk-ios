//
//  ReadFileDataTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/6/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
public struct ReadFilesResponse: ResponseCodable {
	public let files: [File]
}

@available (iOS 13.0, *)
public struct ReadFileDataTaskSettings {
	public init(readPrivateFiles: Bool, readSettings: Set<ReadCommandSettings> = []) {
		self.readPrivateFiles = readPrivateFiles
		self.readSettings = readSettings
	}
	
	let readPrivateFiles: Bool
	let fileIndex: Int = 0
	let readSettings: Set<ReadCommandSettings>
}

@available (iOS 13.0, *)
public class ReadFileDataTask: CardSessionRunnable {
	
	public init(settings: ReadFileDataTaskSettings, fileIndex: Int = 0) {
		self.settings = settings
		self.fileIndex = fileIndex
	}
	
	public typealias CommandResponse = ReadFilesResponse
	
	public var requiresPin2: Bool { settings.readPrivateFiles }
	
	private let settings: ReadFileDataTaskSettings
	
	private var fileIndex: Int
	private var files: [File] = []
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<ReadFilesResponse>) {
		performReadFileDataCommand(session: session, completion: completion)
	}
	
	private func performReadFileDataCommand(session: CardSession, completion: @escaping CompletionResult<ReadFilesResponse>) {
		let command = ReadFileDataCommand(fileIndex: fileIndex, readPrivateFiles: settings.readPrivateFiles)
		command.run(in: session) { (result) in
			switch result {
			case .success(let response):
				let file = File(response: response)
				self.files.append(file)
				self.fileIndex = file.fileIndex + 1
				self.performReadFileDataCommand(session: session, completion: completion)
			case .failure(let error):
				if case TangemSdkError.fileNotFound = error {
					completion(.success(ReadFilesResponse(files: self.files)))
				} else {
					completion(.failure(error))
				}
			}
		}
	}
	
}
