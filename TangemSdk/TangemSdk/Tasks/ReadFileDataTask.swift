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
	let readPrivateFiles: Bool
	let readSettings: Set<ReadFileCommandSettings>
	
	public init(readPrivateFiles: Bool, readSettings: Set<ReadFileCommandSettings> = []) {
		self.readPrivateFiles = readPrivateFiles
		self.readSettings = readSettings
	}
}

@available (iOS 13.0, *)
public class ReadFileDataTask: CardSessionRunnable {
	
	public typealias CommandResponse = ReadFilesResponse
	
	public var requiresPin2: Bool { settings.readPrivateFiles }
	
	private let settings: ReadFileDataTaskSettings
	
	private var fileIndex: Int
	private var files: [File] = []
	
	public init(settings: ReadFileDataTaskSettings, fileIndex: Int = 0) {
		self.settings = settings
		self.fileIndex = fileIndex
	}
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<ReadFilesResponse>) {
		performReadFileDataCommand(session: session, completion: completion)
	}
	
	private func performReadFileDataCommand(session: CardSession, completion: @escaping CompletionResult<ReadFilesResponse>) {
		let command = ReadFileDataCommand(fileIndex: fileIndex, readPrivateFiles: settings.readPrivateFiles)
		command.run(in: session) { (result) in
			switch result {
			case .success(let response):
				print("Success file response: \(response)")
				if !response.fileData.isEmpty {
					let file = File(response: response)
					self.files.append(file)
				}
				self.fileIndex = response.fileIndex + 1
				self.performReadFileDataCommand(session: session, completion: completion)
			case .failure(let error):
				if case TangemSdkError.fileNotFound = error {
					print("Receive files not found error. Files: \(self.files)")
					completion(.success(ReadFilesResponse(files: self.files)))
				} else {
					completion(.failure(error))
				}
			}
		}
	}
	
}
