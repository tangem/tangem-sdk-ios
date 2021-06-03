//
//  WriteFileCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/7/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response for `WriteFileCommand`
@available (iOS 13.0, *)
public struct WriteFileResponse: JSONStringConvertible {
	public let cardId: String
	public let fileIndex: Int?
}

/// Command for writing file on card
@available (iOS 13.0, *)
public final class WriteFileCommand: Command {
	public typealias Response = WriteFileResponse
	
	public var requiresPin2: Bool { dataToWrite.requiredPin2 }
	
	private static let singleWriteSize = 900
	private static let maxSize = 48 * 1024
	
	private let dataToWrite: DataToWrite
	
	private var mode: FileDataMode = .initiateWritingFile
	private var offset: Int = 0
	private var fileIndex: Int = 0
	
	public init(dataToWrite: DataToWrite) {
		self.dataToWrite = dataToWrite
	}
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<WriteFileResponse>) {
		writeFileData(session: session, completion: completion)
	}
	
	func performPreCheck(_ card: Card) -> TangemSdkError? {
		if card.firmwareVersion < FirmwareConstraints.AvailabilityVersions.files,
			card.firmwareVersion < dataToWrite.minFirmwareVersion {
			return .notSupportedFirmwareVersion
		}
		
		if card.status == .notPersonalized {
			return .notPersonalized
		}
		if card.isActivated {
			return .notActivated
		}
		if dataToWrite.data.count > WriteFileCommand.maxSize {
			return .dataSizeTooLarge
		}
		if let dataToWrite = dataToWrite as? FileDataProtectedBySignature {
			if !isCounterValid(issuerDataCounter: dataToWrite.counter, card: card) {
				return .missingCounter
			}
			guard let publicKey = dataToWrite.issuerPublicKey else {
				return .missingIssuerPublicKey
			}
			guard
				let cardId = card.cardId,
				verifySignatures(publicKey: publicKey, cardId: cardId) else {
				return .verificationFailed
			}
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
			try dataToWrite.addStartingTlvData(tlvBuilder, withEnvironment: environment)
				.append(.size, value: dataToWrite.data.count)
		case .writeFile:
			try tlvBuilder.append(.issuerData, value: getDataToWrite())
				.append(.offset, value: offset)
				.append(.fileIndex, value: fileIndex)
		case .confirmWritingFile:
			try dataToWrite.addFinalizingTlvData(tlvBuilder, withEnvironment: environment)
				.append(.fileIndex, value: fileIndex)
		default:
			break
		}
		
		return CommandApdu(.writeFileData, tlv: tlvBuilder.serialize())
	}
	
	func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> WriteFileResponse {
		guard let tlv = apdu.getTlvData() else {
			throw TangemSdkError.deserializeApduFailed
		}
		let decoder = TlvDecoder(tlv: tlv)
		return WriteFileResponse(cardId: try decoder.decode(.cardId),
									 fileIndex: try decoder.decodeOptional(.fileIndex))
	}
	
	// MARK: Private functions
	
	private func writeFileData(session: CardSession, completion: @escaping CompletionResult<WriteFileResponse>) {
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
					self.offset += WriteFileCommand.singleWriteSize
					if self.offset >= self.dataToWrite.data.count {
						self.mode = .confirmWritingFile
					}
					self.writeFileData(session: session, completion: completion)
				case .confirmWritingFile:
					completion(.success(WriteFileResponse(cardId: response.cardId, fileIndex: self.fileIndex)))
				default:
					completion(.failure(.wrongInteractionMode))
				}
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	private func getDataToWrite() -> Data {
		dataToWrite.data[offset..<offset+calculatePartSize()]
	}
	
	private func calculatePartSize() -> Int {
		let bytesLeft = dataToWrite.data.count - offset
		return min(WriteFileCommand.singleWriteSize, bytesLeft)
	}
	
	private func isCounterValid(issuerDataCounter: Int?, card: Card) -> Bool {
		isCounterRequired(card: card) ?
			issuerDataCounter != nil :
			true
	}
	
	private func isCounterRequired(card: Card) -> Bool {
		if dataToWrite.requiredPin2 { return false }
		return card.settingsMask?.contains(.protectIssuerDataAgainstReplay) ?? true
	}
	
	private func verifySignatures(publicKey: Data, cardId: String) -> Bool {
		guard let dataToWrite = dataToWrite as? FileDataProtectedBySignature else {
			return true
		}
		let startingSignatureIsValid = IssuerDataVerifier.verify(cardId: cardId,
																 issuerDataSize: dataToWrite.data.count,
																 issuerDataCounter: dataToWrite.counter,
																 publicKey: publicKey,
																 signature: dataToWrite.startingSignature)
		let finalizingSignatureIsValid = IssuerDataVerifier.verify(cardId: cardId,
																   issuerData: dataToWrite.data,
																   issuerDataCounter: dataToWrite.counter,
																   publicKey: publicKey,
																   signature: dataToWrite.finalizingSignature)
		return startingSignatureIsValid && finalizingSignatureIsValid
	}
	
}
