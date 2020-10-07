//
//  ReadFileCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/6/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
struct ReadFileDataResponse: ResponseCodable {
	let cardId: String
	let size: Int?
	let fileData: Data
	let fileIndex: Int
	let fileSettings: FileSettings
	let fileDataSignature: Data?
	let fileDataCounter: Int?
}

@available (iOS 13.0, *)
public struct ReadFileCommandResponse: ResponseCodable {
	let file: File
	
	static let emptyResponse: ReadFileCommandResponse = ReadFileCommandResponse(file: .emptyFile)
}

@available (iOS 13.0, *)
final class ReadFileDataCommand: Command {
	typealias CommandResponse = ReadFileDataResponse
	
	var requiresPin2: Bool { readPrivateFiles }
	
	private let fileIndex: Int
	private let readPrivateFiles: Bool
	
	private var fileData: Data = Data()
	private var offset: Int = 0
	private var dataSize: Int = 0
	private var fileSettings: FileSettings? = nil
	
	init(fileIndex: Int, readPrivateFiles: Bool) {
		self.fileIndex = fileIndex
		self.readPrivateFiles = readPrivateFiles
	}
	
	func run(in session: CardSession, completion: @escaping CompletionResult<ReadFileCommandResponse>) {
		readFileData(session: session, completion: completion)
	}
	
	func performPreCheck(_ card: Card) -> TangemSdkError? {
		guard card.status == CardStatus.notPersonalized else { return nil }
		return .notPersonalized
	}
	
	func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
		if requiresPin2, case TangemSdkError.invalidParams = error {
			return .pin2OrCvcRequired
		}
		return error
	}
	
	private func readFileData(session: CardSession, completion: @escaping CompletionResult<ReadFileCommandResponse>) {
		transieve(in: session) { (result) in
			switch result {
			case .success(let response):
				if let size = response.size {
					if size == 0 {
						completion(.success(.emptyResponse))
						return
					}
					self.dataSize = size
					self.fileSettings = response.fileSettings
				}
				self.fileData += response.fileData
				guard response.fileDataCounter == nil else {
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
	
	private func completeTask(_ data: ReadFileDataResponse, completion: @escaping CompletionResult<ReadFileCommandResponse>) {
		completion(.success(.init(file: File(fileIndex: fileIndex, fileSettings: data.fileSettings, fileData: fileData))))
	}
	
	func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
		var tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
			.append(.pin, value: environment.pin1.value)
			.append(.cardId, value: environment.card?.cardId)
			.append(.fileIndex, value: fileIndex)
			.append(.offset, value: offset)
		if readPrivateFiles {
			tlvBuilder = try tlvBuilder.append(.pin2, value: environment.pin2.value)
		}
		return CommandApdu(.readFileData, tlv: tlvBuilder.serialize())
	}
	
	func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadFileDataResponse {
		guard let tlv = apdu.getTlvData() else {
			throw TangemSdkError.deserializeApduFailed
		}
		let decoder = TlvDecoder(tlv: tlv)
		return ReadFileDataResponse(cardId: try decoder.decode(.cardId),
									size: try decoder.decodeOptional(.size),
									fileData: try decoder.decodeOptional(.issuerData) ?? Data(),
									fileIndex: try decoder.decodeOptional(.fileIndex) ?? 0,
									fileSettings: try decoder.decodeOptional(.fileSettings) ?? .public,
									fileDataSignature: try decoder.decodeOptional(.issuerDataSignature),
									fileDataCounter: try decoder.decodeOptional(.issuerDataCounter))
	}
}
