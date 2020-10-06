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
	let files: [File]
}

@available (iOS 13.0, *)
public class ReadFileDataTask: CardSessionRunnable {
	
	public init(readPrivateFiles: Bool, fileIndex: Int = 0, files: [File] = [File]()) {
		self.readPrivateFiles = readPrivateFiles
		self.fileIndex = fileIndex
		self.files = files
	}
	
	public typealias CommandResponse = ReadFilesResponse
	
	public var requiresPin2: Bool { readPrivateFiles }
	
	private let readPrivateFiles: Bool
	
	private var fileIndex: Int
	private var files: [File]
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<ReadFilesResponse>) {
		performReadFileDataCommand(session: session, completion: completion)
	}
	
	private func performReadFileDataCommand(session: CardSession, completion: @escaping CompletionResult<ReadFilesResponse>) {
		let command = ReadFileDataCommand(fileIndex: fileIndex, readPrivateFiles: readPrivateFiles)
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
