//
//  ReadFileCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/6/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response for `ReadFileCommand`
@available (iOS 13.0, *)
public struct ReadFileResponse: JSONStringConvertible {
    public let cardId: String
    public let size: Int?
    public let fileData: Data
    public let fileIndex: Int
    public let fileSettings: FileSettings
    public let fileDataSignature: Data?
    public let fileDataCounter: Int?
    public let walletIndex: Int?
}

/// Command that read single file at specified index. Reading private file will prompt user to input a passcode.
@available (iOS 13.0, *)
public final class ReadFileCommand: Command {
    public var requiresPasscode: Bool { readPrivateFiles }
    
    private let filename: String?
    private let walletPublicKey: Data?
    private var walletIndex: Int?
    private let readPrivateFiles: Bool
    
    private var fileData: Data = Data()
    private var fileIndex: Int = 0
    private var offset: Int = 0
    private var dataSize: Int = 0
    private var fileSettings: FileSettings? = nil
    private var files: [File] = []
    
    public init(filename: String? = nil, walletPublicKey: Data? = nil, readPrivateFiles: Bool = false) {
        self.filename = filename
        self.walletPublicKey = walletPublicKey
        self.readPrivateFiles = readPrivateFiles
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .filesAvailable {
            return .notSupportedFirmwareVersion
        }
        
        return nil
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<[File]>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        if let walletPublicKey = self.walletPublicKey { //optimization
            self.walletIndex = card.wallets[walletPublicKey]?.index
        }
        
        readAllFiles(session: session, completion: completion)
    }
    
    private func readAllFiles(session: CardSession, completion: @escaping CompletionResult<[File]>) {
        self.offset = 0
        self.dataSize = 0
        self.fileData = Data()
        
        readFileData(session: session) { result in
            switch result {
            case .success(let response):
                if !response.fileData.isEmpty {
                    let file = File(response: response)
                    self.files.append(file)
                }
                self.fileIndex = response.fileIndex + 1
                self.readAllFiles(session: session, completion: completion)
            case .failure(let error):
                if case TangemSdkError.fileNotFound = error {
                    completion(.success(self.files))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func readFileData(session: CardSession, completion: @escaping CompletionResult<ReadFileResponse>) {
        transceive(in: session) { (result) in
            switch result {
            case .success(let response):
                if let size = response.size {
                    if size == 0 {
                        completion(.success(response))
                        return
                    }
                    self.dataSize = size
                    self.fileSettings = response.fileSettings
                }
                self.fileData += response.fileData
                guard self.fileData.count < self.dataSize else {
                    self.completeTask(response, completion: completion)
                    return
                }
                self.offset = self.fileData.count
                self.readFileData(session: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func completeTask(_ data: ReadFileResponse, completion: @escaping CompletionResult<ReadFileResponse>) {
        let response = ReadFileResponse(cardId: data.cardId,
                                        size: dataSize,
                                        fileData: fileData,
                                        fileIndex: data.fileIndex,
                                        fileSettings: fileSettings ?? data.fileSettings,
                                        fileDataSignature: data.fileDataSignature,
                                        fileDataCounter: data.fileDataCounter,
                                        walletIndex: data.walletIndex)
        completion(.success(response))
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.fileIndex, value: fileIndex)
            .append(.offset, value: offset)
        
        if let filename = self.filename {
            try tlvBuilder.append(.fileTypeName, value: filename)
        }
        
        if let walletIndex = self.walletIndex {
            try tlvBuilder.append(.walletIndex, value: walletIndex) //todo check it!
        }
        
        if readPrivateFiles {
            try tlvBuilder.append(.pin2, value: environment.passcode.value)
        }
        
        return CommandApdu(.readFileData, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadFileResponse {
        guard let tlv = apdu.getTlvData() else {
            throw TangemSdkError.deserializeApduFailed
        }
        let decoder = TlvDecoder(tlv: tlv)
        return ReadFileResponse(cardId: try decoder.decode(.cardId),
                                size: try decoder.decode(.size),
                                fileData: try decoder.decode(.issuerData) ?? Data(),
                                fileIndex: try decoder.decode(.fileIndex) ?? 0,
                                fileSettings: try decoder.decode(.fileSettings) ?? .readAccessCode,
                                fileDataSignature: try decoder.decode(.issuerDataSignature),
                                fileDataCounter: try decoder.decode(.issuerDataCounter),
                                walletIndex: try decoder.decode(.walletIndex))
    }
}
