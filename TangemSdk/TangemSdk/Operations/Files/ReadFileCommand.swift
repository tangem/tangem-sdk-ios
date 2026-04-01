//
//  ReadFileCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response for `ReadFileCommand`
struct ReadFileResponse: JSONStringConvertible {
    var cardId: String
    var size: Int?
    var offset: Int?
    var fileData: Data
    var fileIndex: Int
    var settings: FileSettings?
    var ownerIndex: Int?
    var ownerPublicKey: Data?
    var walletIndex: Int?

    fileprivate var isReadComplete: Bool {
        guard let size = size else { return true }

        return fileData.count == size
    }

    fileprivate static var empty: ReadFileResponse {
        return ReadFileResponse(
            cardId: "",
            size: nil,
            offset: nil,
            fileData: Data(),
            fileIndex: 0,
            settings: nil,
            ownerIndex: nil,
            ownerPublicKey: nil,
            walletIndex: nil
        )
    }

    fileprivate mutating func update(with response: ReadFileResponse) {
        cardId = response.cardId
        fileIndex = response.fileIndex

        response.size.map { size = $0 }
        response.settings.map { settings = $0 }
        response.ownerIndex.map { ownerIndex = $0 }
        response.ownerPublicKey.map { ownerPublicKey = $0 }
        response.walletIndex.map { walletIndex = $0 }
        response.offset.map { offset = $0 }

        fileData += response.fileData
    }
}

/// Command that read single file at specified index. Reading private file will prompt user to input a passcode.
final class ReadFileCommand: Command {
    /// If true, user code or security delay will be requested
    var shouldReadPrivateFiles = false

    var requiresPasscode: Bool { shouldReadPrivateFiles }

    // Read filters
    private let fileIndex: Int
    private let fileName: String?
    private let walletPublicKey: Data?
    private var walletIndex: Int?

    private var aggregatedResponse: ReadFileResponse = .empty

    init(fileIndex: Int, fileName: String? = nil, walletPublicKey: Data? = nil) {
        self.fileIndex = fileIndex
        self.fileName = fileName
        self.walletPublicKey = walletPublicKey
    }

    deinit {
        Log.debug("ReadFileCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .filesAvailable {
            return .notSupportedFirmwareVersion
        }

        return nil
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<File?>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        if let walletPublicKey = walletPublicKey { // optimization
            walletIndex = card.wallets[walletPublicKey]?.index

            if walletIndex == nil {
                completion(.failure(.walletNotFound))
                return
            }
        }

        readFileData(session: session) { result in
            switch result {
            case .success:
                completion(.success(File(response: self.aggregatedResponse)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func readFileData(session: CardSession, completion: @escaping CompletionResult<Void>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                self.aggregatedResponse.update(with: response)

                if self.aggregatedResponse.isReadComplete {
                    completion(.success(()))
                    return
                }

                self.readFileData(session: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.fileIndex, value: fileIndex)
            .append(.offset, value: aggregatedResponse.fileData.count)

        if let fileName = fileName {
            try tlvBuilder.append(.fileTypeName, value: fileName)
        }

        if let walletIndex = walletIndex {
            try tlvBuilder.append(.walletIndex, value: walletIndex)
        }

        guard let card = environment.card else {
            throw TangemSdkError.missingPreflightRead
        }

        if shouldReadPrivateFiles {
            try tlvBuilder.append(.pin, value: environment.accessCode.value)
                .append(.pin2, value: environment.passcode.value)
        } else {
            if card.firmwareVersion < .multiwalletAvailable {
                try tlvBuilder.append(.pin, value: environment.accessCode.value)
            }
        }

        return CommandApdu(.readFileData, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadFileResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)

        return ReadFileResponse(
            cardId: try decoder.decode(.cardId),
            size: try decoder.decode(.size),
            offset: try decoder.decode(.offset),
            fileData: try decoder.decode(.data) ?? Data(),
            fileIndex: try decoder.decode(.fileIndex) ?? 0,
            settings: try FileSettings(try decoder.decode(.fileSettings)),
            ownerIndex: try decoder.decode(.fileOwnerIndex),
            ownerPublicKey: try decoder.decode(.issuerPublicKey),
            walletIndex: try decoder.decode(.walletIndex)
        )
    }
}
