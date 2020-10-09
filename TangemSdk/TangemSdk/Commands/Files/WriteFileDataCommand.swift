//
//  WriteFileDataCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/7/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
public struct WriteFileDataResponse: ResponseCodable {
	let cardId: String
	let fileIndex: Int?
}

@available (iOS 13.0, *)
public struct FileDataToWrite {
	let data: DataToWrite
	let startingSignature: Data
	let finalizingSignature: Data
}

@available (iOS 13.0, *)
public final class WriteFileDataCommand: Command {
	public init(data: Data, startingSignature: Data, finalizingSignature: Data, dataCounter: Int?, issuerPublicKey: Data?) {
		self.data = data
		self.startingSignature = startingSignature
		self.finalizingSignature = finalizingSignature
		self.dataCounter = dataCounter
		self.issuerPublicKey = issuerPublicKey
		fileDataToWrite = FileDataToWrite(data: DataToWrite(data: data, settings: []), startingSignature: startingSignature, finalizingSignature: finalizingSignature)
	}
	
	public typealias CommandResponse = WriteFileDataResponse
	
	private static let singleWriteSize = 1524
	private static let maxSize = 48 * 1024
	
	private let fileDataToWrite: FileDataToWrite
	private let data: Data
	private let startingSignature: Data
	private let finalizingSignature: Data
	private let dataCounter: Int?
	private let issuerPublicKey: Data?
	
	private var mode: FileDataMode = .initiateWritingFile
	private var offset: Int = 0
	private var fileIndex: Int = 0
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<WriteFileDataResponse>) {
		writeFileData(session: session, completion: completion)
	}
	
	func performPreCheck(_ card: Card) -> TangemSdkError? {
		guard
			let firmwareVersion = card.firmwareVersionValue,
			firmwareVersion >= FirmwareConstraints.minVersionForFiles,
			firmwareVersion >= fileDataToWrite.data.settings.minFirmwareVersion()
			else {
			return .notSupportedFirmwareVersion
		}
		
		guard let publicKey = issuerPublicKey ?? card.issuerPublicKey else {
			return .missingIssuerPublicKey
		}
		if card.status == .notPersonalized {
			return .notPersonalized
		}
		if card.isActivated {
			return .notActivated
		}
		if data.count > WriteFileDataCommand.maxSize {
			return .dataSizeTooLarge
		}
		guard isCounterValid(issuerDataCounter: dataCounter, card: card) else {
			return .missingCounter
		}
		guard
			let cardId = card.cardId,
			verifySignatures(publicKey: publicKey, cardId: cardId) else {
			return .verificationFailed
		}
		return nil
	}
	
	func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
		if case .invalidParams = error,
		   let card = card,
		   isCounterRequired(card: card) {
			return .dataCannotBeWritten
		}
		if case .invalidState = error, card?.settingsMask?.contains(.protectIssuerDataAgainstReplay) ?? true {
			return .overwritingDataIsProhibited
		}
		return error
	}
	
	func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
		let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
			.append(.cardId, value: environment.card?.cardId)
			.append(.pin, value: environment.pin1.value)
			.append(.interactionMode, value: mode)
		switch mode {
		case .initiateWritingFile:
			try tlvBuilder.append(.size, value: data.count)
			try tlvBuilder.append(.issuerDataSignature, value: startingSignature)
			try tlvBuilder.append(.issuerDataCounter, value: dataCounter)
		case .writeFile:
			try tlvBuilder.append(.issuerData, value: getDataToWrite())
			try tlvBuilder.append(.offset, value: offset)
			try tlvBuilder.append(.fileIndex, value: fileIndex)
		case .confirmWritingFile:
			try tlvBuilder.append(.fileIndex, value: fileIndex)
			try tlvBuilder.append(.issuerDataSignature, value: finalizingSignature)
		default:
			break
		}
		
		return CommandApdu(.writeFileData, tlv: tlvBuilder.serialize())
	}
	
	func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> WriteFileDataResponse {
		guard let tlv = apdu.getTlvData() else {
			throw TangemSdkError.deserializeApduFailed
		}
		let decoder = TlvDecoder(tlv: tlv)
		return WriteFileDataResponse(cardId: try decoder.decode(.cardId),
									 fileIndex: try decoder.decodeOptional(.fileIndex))
	}
	
	// MARK: Private functions
	
	private func writeFileData(session: CardSession, completion: @escaping CompletionResult<WriteFileDataResponse>) {
		// TODO: Insert view delegate method to display progress to user
		transieve(in: session) { (result) in
			switch result {
			case .success(let response):
				switch self.mode {
				case .initiateWritingFile:
					self.fileIndex = response.fileIndex ?? 0
					self.mode = .writeFile
					self.writeFileData(session: session, completion: completion)
				case .writeFile:
					self.offset += WriteFileDataCommand.singleWriteSize
					if self.offset >= self.data.count {
						self.mode = .confirmWritingFile
					}
					self.writeFileData(session: session, completion: completion)
				case .confirmWritingFile:
					completion(.success(WriteFileDataResponse(cardId: response.cardId, fileIndex: response.fileIndex)))
				default:
					completion(.failure(.wrongInteractionMode))
				}
			case .failure(let error):
				if session.environment.handleErrors {
					let error = self.mapError(session.environment.card, error)
					completion(.failure(error))
					return
				}
				completion(.failure(error))
			}
		}
	}
	
	private func getDataToWrite() -> Data {
		data[offset..<offset+calculatePartSize()]
	}
	
	private func calculatePartSize() -> Int {
		let bytesLeft = data.count - offset
		return min(WriteFileDataCommand.singleWriteSize, bytesLeft)
	}
	
	private func isCounterValid(issuerDataCounter: Int?, card: Card) -> Bool {
		isCounterRequired(card: card) ?
			issuerDataCounter != nil :
			true
	}
	
	private func isCounterRequired(card: Card) -> Bool {
		card.settingsMask?.contains(.protectIssuerDataAgainstReplay) ?? true
	}
	
	private func verifySignatures(publicKey: Data, cardId: String) -> Bool {
		let startingSignatureIsValid = IssuerDataVerifier.verify(cardId: cardId, issuerDataSize: data.count, issuerDataCounter: dataCounter, publicKey: publicKey, signature: startingSignature)
	let finalizingSignatureIsValid = IssuerDataVerifier.verify(cardId: cardId, issuerData: data, issuerDataCounter: dataCounter, publicKey: publicKey, signature: finalizingSignature)
		return startingSignatureIsValid && finalizingSignatureIsValid
	}
	
}
