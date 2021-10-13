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
struct ReadFileResponse: JSONStringConvertible {
    let cardId: String
    let size: Int?
    let fileData: Data
    let fileIndex: Int
    let fileSettings: FileSettings
    let fileDataSignature: Data?
    let fileDataCounter: Int?
    let walletIndex: Int?
}

/// Command that read single file at specified index. Reading private file will prompt user to input a passcode.
@available (iOS 13.0, *)
final class ReadFileCommand: Command {
    ///If true, user code or security delay will be requested
    var shouldReadPrivateFiles = false
    
    var requiresPasscode: Bool { shouldReadPrivateFiles }
    
    //Read filters
    private let fileIndex: Int
    private let fileName: String?
    private let walletPublicKey: Data?
    private var walletIndex: Int?
    
    private var fileData: Data = Data()
    private var offset: Int = 0
    private var dataSize: Int = 0
    private var fileSettings: FileSettings? = nil
    
    init(fileIndex: Int, fileName: String? = nil, walletPublicKey: Data? = nil) {
        self.fileIndex = fileIndex
        self.fileName = fileName
        self.walletPublicKey = walletPublicKey
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .filesAvailable {
            return .notSupportedFirmwareVersion
        }
        
        if !card.settings.isFilesAllowed {
            return .filesDisabled
        }
        
        return nil
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<ReadFileResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        if let walletPublicKey = self.walletPublicKey { //optimization
            self.walletIndex = card.wallets[walletPublicKey]?.index
            
            if self.walletIndex == nil {
                completion(.failure(.walletNotFound))
                return
            }
        }
        
        readFileData(session: session, completion: completion)
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
            .append(.cardId, value: environment.card?.cardId)
            .append(.fileIndex, value: fileIndex)
            .append(.offset, value: offset)
        
        if let fileName = self.fileName {
            try tlvBuilder.append(.fileTypeName, value: fileName)
        }
        
        if let walletIndex = self.walletIndex {
            try tlvBuilder.append(.walletIndex, value: walletIndex)
        }
        
        guard let card = environment.card else {
            throw TangemSdkError.missingPreflightRead
        }
        
        if shouldReadPrivateFiles {
            try tlvBuilder.append(.pin, value: environment.accessCode.value)
                .append(.pin2, value: environment.passcode.value)
        } else {
            if card.firmwareVersion.doubleValue < 4 {
                try tlvBuilder.append(.pin, value: environment.accessCode.value)
            }
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
                                fileSettings: try FileSettings(decoder.decode(.fileSettings)),
                                fileDataSignature: try decoder.decode(.issuerDataSignature),
                                fileDataCounter: try decoder.decode(.issuerDataCounter),
                                walletIndex: try decoder.decode(.walletIndex))
    }
}
