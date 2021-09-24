//
//  ReadFilesTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/6/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// This task requesting information about files saved on card. Task can read private files
@available (iOS 13.0, *)
public class ReadFilesTask: CardSessionRunnable {
    public var shouldReadPrivateFiles = false
    
    private let fileName: String?
    private let walletPublicKey: Data?
    
    private var files: [File] = []
    
    public init(fileName: String? = nil, walletPublicKey: Data? = nil) {
        self.fileName = fileName
        self.walletPublicKey = walletPublicKey
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<[File]>) {
        readAllFiles(fileIndex: 0, session: session, completion: completion)
    }
    
    private func readAllFiles(fileIndex: Int, session: CardSession, completion: @escaping CompletionResult<[File]>) {
        let command = ReadFileCommand(fileIndex: fileIndex, fileName: fileName, walletPublicKey: walletPublicKey)
        command.shouldReadPrivateFiles = self.shouldReadPrivateFiles
        
        command.run(in: session) { (result) in
            switch result {
            case .success(let response):
                if !response.fileData.isEmpty {
                    let file = File(response: response)
                    self.files.append(file)
                }
                
                self.readAllFiles(fileIndex: response.fileIndex + 1, session: session, completion: completion)
            case .failure(let error):
                if case TangemSdkError.fileNotFound = error {
                    completion(.success(self.files))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
}

