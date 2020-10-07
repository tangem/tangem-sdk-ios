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
public struct ReadFileDataTaskSettings {
	public init(readPrivateFiles: Bool, shouldValidateFiles: Bool) {
		self.readPrivateFiles = readPrivateFiles
		self.shouldValidateFiles = shouldValidateFiles
	}
	
	let readPrivateFiles: Bool
	let fileIndex: Int = 0
	let shouldValidateFiles: Bool
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
				var file = response.file
				self.files.append(response.file)
				self.settings.shouldValidateFiles ?
					self.performReadFileChecksumCommand(session: session, for: &file, completion: completion) :
					self.readNextFile(session: session, lastFileIndex: file.fileIndex, completion: completion)
			case .failure(let error):
				if case TangemSdkError.fileNotFound = error {
					completion(.success(ReadFilesResponse(files: self.files)))
				} else {
					completion(.failure(error))
				}
			}
		}
	}
	
	private func readNextFile(session: CardSession, lastFileIndex: Int, completion: @escaping CompletionResult<ReadFilesResponse>) {
		fileIndex = lastFileIndex + 1
		performReadFileDataCommand(session: session, completion: completion)
	}
	
	private func performReadFileChecksumCommand(session: CardSession, for file: inout File, completion: @escaping CompletionResult<ReadFilesResponse>) {
		let command = ReadFileChecksumCommand(fileIndex: file.fileIndex, readPrivateFiles: settings.readPrivateFiles)
		command.run(in: session) { [file] (result) in
			switch result {
			case .success(let response):
				let loadedFileChecksum = file.fileData.getSha256()
				let status: FileValidation = loadedFileChecksum == response.checksum ? .valid : .corrupted
			case .failure(let  error):
				print("Failed to read file checksum", error)
			}
			self.readNextFile(session: session, lastFileIndex: file.fileIndex, completion: completion)
		}
	}
	
}
