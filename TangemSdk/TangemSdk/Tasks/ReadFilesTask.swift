//
//  ReadFilesTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/6/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
public struct ReadFilesResponse: JSONStringConvertible {
	public let files: [File]
}

@available (iOS 13.0, *)
public class ReadFilesTask: CardSessionRunnable {
	
	public typealias CommandResponse = ReadFilesResponse
	
	public var requiresPin2: Bool { readPrivateFiles }
	
    private let readPrivateFiles: Bool
    private let indicies: [Int]
	private var index: Int = 0
	private var files: [File] = []
	
    public init(readPrivateFiles: Bool, indicies: [Int]? = nil) {
        self.readPrivateFiles = readPrivateFiles
		self.indicies = indicies ?? []
	}
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<ReadFilesResponse>) {
        if indicies.isEmpty {
            readAllFiles(session: session, completion: completion)
        } else {
            readSpecifiedFiles(indicies: indicies, session: session, completion: completion)
        }
	}
	
	private func readAllFiles(session: CardSession, completion: @escaping CompletionResult<ReadFilesResponse>) {
		let command = ReadFileCommand(fileIndex: index, readPrivateFiles: readPrivateFiles)
		command.run(in: session) { (result) in
			switch result {
			case .success(let response):
				if !response.fileData.isEmpty {
					let file = File(response: response)
					self.files.append(file)
				}
				self.index = response.fileIndex + 1
				self.readAllFiles(session: session, completion: completion)
			case .failure(let error):
				if case TangemSdkError.fileNotFound = error {
                    Log.debug("Receive files not found error. Files: \(self.files)")
					completion(.success(ReadFilesResponse(files: self.files)))
				} else {
					completion(.failure(error))
				}
			}
		}
	}
    
    private func readSpecifiedFiles(indicies: [Int], session: CardSession, completion: @escaping CompletionResult<ReadFilesResponse>) {
        let command = ReadFileCommand(fileIndex: indicies[index], readPrivateFiles: readPrivateFiles)
        command.run(in: session) { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let file = File(response: response)
                self.files.append(file)
                
                if self.index == indicies.last {
                    completion(.success(ReadFilesResponse(files: self.files)))
                    return
                }
                
                self.index += 1
                self.readSpecifiedFiles(indicies: indicies, session: session, completion: completion)
            }
        }
    }
	
}

