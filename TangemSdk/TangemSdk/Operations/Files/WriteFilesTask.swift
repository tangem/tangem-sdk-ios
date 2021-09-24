//
//  WriteFilesTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Response for `WriteFilesTask`.
/// - Parameters:
///   - cardId: CID, Unique Tangem card ID number
///   - fileIndices: Indicies of created files
@available (iOS 13.0, *)
public struct WriteFilesResponse: JSONStringConvertible {
    public let cardId: String
    public let filesIndices: [Int]
}

/// This task allows to write multiple files to a card.
/// There are two secure ways to write files.
/// 1. Data can be signed by Issuer (the one specified on card during personalization)
/// 2. Data can be protected by Passcode (PIN2).  In this case,  Passcode (PIN2) is required for the command.
@available (iOS 13.0, *)
public final class WriteFilesTask: CardSessionRunnable {
    private let userFiles: [UserFile]
    private let ownerFiles: [OwnerFile]
    
    private var savedFilesIndices: [Int] = []
    
    public init?(files: [UserFile]) {
        if files.isEmpty {
            return nil
        }
        
        self.userFiles = files
        self.ownerFiles = []
    }
    
    public init?(files: [OwnerFile]) {
        if files.isEmpty {
            return nil
        }
        
        self.userFiles = []
        self.ownerFiles = files
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<WriteFilesResponse>) {
        if !userFiles.isEmpty {
            writeUserFile(index: 0, session: session, completion: completion)
        } else {
            writeOwnerFile(index: 0, session: session, completion: completion)
        }
    }
    
    private func writeUserFile(index: Int, session: CardSession, completion: @escaping CompletionResult<WriteFilesResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.cardError))
            return
        }
        
        guard index < userFiles.count else {
            completion(.success(.init(cardId: card.cardId, filesIndices: savedFilesIndices)))
            return
        }
        
        let file = userFiles[index]
        
        WriteFileCommand(data: file.data, filePermissions: file.filePermissions, walletPublicKey: file.walletPublicKey)
            .run(in: session) { result in
                switch result {
                case .success(let response):
                    self.savedFilesIndices.append(response.fileIndex ?? 0)
                    self.writeUserFile(index: index + 1, session: session, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    private func writeOwnerFile(index: Int, session: CardSession, completion: @escaping CompletionResult<WriteFilesResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.cardError))
            return
        }
        
        guard index < ownerFiles.count else {
            completion(.success(.init(cardId: card.cardId, filesIndices: savedFilesIndices)))
            return
        }
        
        let file = ownerFiles[index]
        
        WriteFileCommand(data: file.data,
                         startingSignature: file.startingSignature,
                         finalizingSignature: file.finalizingSignature,
                         counter: file.counter,
                         filePermissions: file.filePermissions,
                         walletPublicKey: file.walletPublicKey)
            .run(in: session) { result in
                switch result {
                case .success(let response):
                    self.savedFilesIndices.append(response.fileIndex ?? 0)
                    self.writeOwnerFile(index: index + 1, session: session, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}


@available (iOS 13.0, *)
public typealias UserFile = (data: Data, filePermissions: FilePermissions?, walletPublicKey: Data?)

@available (iOS 13.0, *)
public typealias OwnerFile = (data: Data, startingSignature: Data, finalizingSignature: Data, counter: Int,
                              filePermissions: FilePermissions?, walletPublicKey: Data?)
