//
//  ReadFileChecksumCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/7/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
public struct ReadFileChecksumResponse: JSONStringConvertible {
	public let cardId: String
	public let checksum: Data
	public let fileIndex: Int?
}

@available (iOS 13.0, *)
public final class ReadFileChecksumCommand: Command {
	public typealias CommandResponse = ReadFileChecksumResponse
	
	public var requiresPin2: Bool { readPrivateFiles }
	
	private let fileIndex: Int
	private let readPrivateFiles: Bool
	
	public init(fileIndex: Int, readPrivateFiles: Bool) {
		self.fileIndex = fileIndex
		self.readPrivateFiles = readPrivateFiles
	}
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<ReadFileChecksumResponse>) {
		readFileData(session: session, completion: completion)
	}
	
	func performPreCheck(_ card: Card) -> TangemSdkError? {
		guard card.status == CardStatus.notPersonalized else { return nil }
		
		if card.firmwareVersion < FirmwareConstraints.AvailabilityVersions.files {
			return .notSupportedFirmwareVersion
		}
		
		return .notPersonalized
	}
	
	func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
		if requiresPin2, case TangemSdkError.invalidParams = error {
			return .pin2OrCvcRequired
		}
		return error
	}
	
	private func readFileData(session: CardSession, completion: @escaping CompletionResult<ReadFileChecksumResponse>) {
		transieve(in: session) { (result) in
			switch result {
			case .success(let response):
				completion(.success(response))
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
		var tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
			.append(.pin, value: environment.pin1.value)
			.append(.cardId, value: environment.card?.cardId)
			.append(.fileIndex, value: fileIndex)
			.append(.interactionMode, value: FileDataMode.readFileHash)
		if readPrivateFiles {
			tlvBuilder = try tlvBuilder.append(.pin2, value: environment.pin2.value)
		}
		return CommandApdu(.readFileData, tlv: tlvBuilder.serialize())
	}
	
	func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadFileChecksumResponse {
		guard let tlv = apdu.getTlvData() else {
			throw TangemSdkError.deserializeApduFailed
		}
		let decoder = DefaultTlvDecoder(tlv: tlv)
		return ReadFileChecksumResponse(cardId: try decoder.decode(.cardId),
										checksum: try decoder.decode(.codeHash),
										fileIndex: try decoder.decode(.fileIndex))
	}
}
