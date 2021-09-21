////
////  ReadFilesTask.swift
////  TangemSdk
////
////  Created by Andrew Son on 10/6/20.
////  Copyright © 2020 Tangem AG. All rights reserved.
////
//
//import Foundation
//
///// This task requesting information about files saved on card. Task can read private files
//@available (iOS 13.0, *)
//public class ReadFilesTask: CardSessionRunnable {
//    private let readPrivateFiles: Bool
//    
//    private let filename: String?
//    private let walletPublicKey: Data?
//    private var index: Int = 0
//    private var files: [File] = []
//
//    /// - Parameters:
//    ///   - readPrivateFiles: if you want to read private files - set to `true`
//    public init(filename: String? = nil, walletPublicKey: Data? = nil, readPrivateFiles: Bool = false) {
//        self.filename = filename
//        self.walletPublicKey = walletPublicKey
//        self.readPrivateFiles = readPrivateFiles
//    }
//
//    public func run(in session: CardSession, completion: @escaping CompletionResult<[File]>) {
//        readAllFiles(session: session, completion: completion)
//    }
//
//    private func readAllFiles(session: CardSession, completion: @escaping CompletionResult<[File]>) {
//        let command = ReadFileCommand(fileIndex: index, readPrivateFiles: readPrivateFiles)
//        command.run(in: session) { (result) in
//            switch result {
//            case .success(let response):
//                if !response.fileData.isEmpty {
//                    let file = File(response: response)
//                    self.files.append(file)
//                }
//                self.index = response.fileIndex + 1
//                self.readAllFiles(session: session, completion: completion)
//            case .failure(let error):
//                if case TangemSdkError.fileNotFound = error {
//                    Log.debug("Receive files not found error. Files: \(self.files)")
//                    completion(.success(ReadFilesResponse(files: self.files)))
//                } else {
//                    completion(.failure(error))
//                }
//            }
//        }
//    }
//
//    private func readSpecifiedFiles(indices: [Int], session: CardSession, completion: @escaping CompletionResult<ReadFilesResponse>) {
//        let command = ReadFileCommand(fileIndex: indices[index], readPrivateFiles: readPrivateFiles)
//        command.run(in: session) { (result) in
//            switch result {
//            case .failure(let error):
//                completion(.failure(error))
//            case .success(let response):
//                let file = File(response: response)
//                self.files.append(file)
//
//                if self.index == indices.count - 1 {
//                    completion(.success(ReadFilesResponse(files: self.files)))
//                    return
//                }
//
//                self.index += 1
//                self.readSpecifiedFiles(indices: indices, session: session, completion: completion)
//            }
//        }
//    }
//
//}
//
