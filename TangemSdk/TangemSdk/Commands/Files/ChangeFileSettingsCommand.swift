//
//  ChangeFileSettingsCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
public final class ChangeFileSettingsCommand: Command {
	public typealias CommandResponse = SimpleResponse
	
	public var requiresPin2: Bool { true }
	
	private let fileIndex: Int
	private let newSettings: FileSettings
	
	public init(fileIndex: Int, newSettings: FileSettings) {
		self.fileIndex = fileIndex
		self.newSettings = newSettings
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
			.append(.interactionMode, value: FileDataMode.changeFileSettings)
			.append(.fileIndex, value: fileIndex)
			.append(.fileSettings, value: newSettings)
		return CommandApdu(.writeFileData, tlv: tlvBuilder.serialize())
	}
	
	func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SimpleResponse {
		guard let tlv = apdu.getTlvData() else {
			throw TangemSdkError.deserializeApduFailed
		}
		let decoder = DefaultTlvDecoder(tlv: tlv)
		return SimpleResponse(cardId: try decoder.decode(.cardId))
	}
	
}
