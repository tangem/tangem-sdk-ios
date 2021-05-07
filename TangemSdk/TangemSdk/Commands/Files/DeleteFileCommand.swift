//
//  DeleteFileCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Command that deletes file at specified index
@available (iOS 13.0, *)
public final class DeleteFileCommand: Command {
	public typealias CommandResponse = SimpleResponse
	
	private let fileIndex: Int
	
	public init(fileAt index: Int) {
		fileIndex = index
	}
	
	func performPreCheck(_ card: Card) -> TangemSdkError? {
		if card.status == .notPersonalized {
			return .notPersonalized
		}
		
		if card.firmwareVersion < FirmwareConstraints.AvailabilityVersions.files {
			return .notSupportedFirmwareVersion
		}
		if card.isActivated {
			return .notActivated
		}
		
		return nil
	}
	
	func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
		if case .invalidParams = error {
			return .pin2OrCvcRequired
		}
		return error
	}
	
	func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
		let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
			.append(.cardId, value: environment.card?.cardId)
			.append(.pin, value: environment.pin1.value)
			.append(.pin2, value: environment.pin2.value)
			.append(.interactionMode, value: FileDataMode.deleteFile)
			.append(.fileIndex, value: fileIndex)
		return CommandApdu(.writeFileData, tlv: tlvBuilder.serialize())
	}
	
	func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SimpleResponse {
		guard let tlv = apdu.getTlvData() else {
			throw TangemSdkError.deserializeApduFailed
		}
		let decoder = TlvDecoder(tlv: tlv)
		return SimpleResponse(cardId: try decoder.decode(.cardId))
	}
}
