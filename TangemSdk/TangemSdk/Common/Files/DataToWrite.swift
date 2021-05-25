//
//  DataToWrite.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/7/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
public protocol DataToWrite: FirmwareRestictible {
	var data: Data { get }
	var requiredPin2: Bool { get }
	func addStartingTlvData(_ tlvBuilder: TlvBuilder, withEnvironment environment: SessionEnvironment) throws ->  TlvBuilder
	func addFinalizingTlvData(_ tlvBuilder: TlvBuilder, withEnvironment environment: SessionEnvironment) throws -> TlvBuilder
}

/// Use this type when protecting data with issuer data signature.
/// - Note: To generate starting and finalizing signatures use `FileHashHelper`
@available (iOS 13.0, *)
public struct FileDataProtectedBySignature: DataToWrite {
	public let data: Data
	
	public var requiredPin2: Bool { false }
	public var minFirmwareVersion: FirmwareVersion { settings.minFirmwareVersion() }
	public var maxFirmwareVersion: FirmwareVersion { settings.maxFirmwareVersion() }
	
	let startingSignature: Data
	let finalizingSignature: Data
	let counter: Int
	let issuerPublicKey: Data?
	var settings: Set<FileWriteSettings> = [.none]
	
	public init(data: Data, startingSignature: Data, finalizingSignature: Data, counter: Int, issuerPublicKey: Data?) {
		self.data = data
		self.startingSignature = startingSignature
		self.finalizingSignature = finalizingSignature
		self.counter = counter
		self.issuerPublicKey = issuerPublicKey
		self.settings = [.none]
	}
	
	public func addStartingTlvData(_ tlvBuilder: TlvBuilder, withEnvironment environment: SessionEnvironment) throws -> TlvBuilder {
		try tlvBuilder.append(.issuerDataSignature, value: startingSignature)
			.append(.issuerDataCounter, value: counter)
            .append(.fileSettings, value: FileSettings.public)
	}
	
	public func addFinalizingTlvData(_ tlvBuilder: TlvBuilder, withEnvironment environment: SessionEnvironment) throws -> TlvBuilder {
		try tlvBuilder.append(.issuerDataSignature, value: finalizingSignature)
	}
	
}

/// Use this type when protecting data with passcode
@available (iOS 13.0, *)
public struct FileDataProtectedByPasscode: DataToWrite {
	public let data: Data
	
	public var requiredPin2: Bool { true }
	public var minFirmwareVersion: FirmwareVersion { settings.minFirmwareVersion() }
	public var maxFirmwareVersion: FirmwareVersion { settings.maxFirmwareVersion() }
	
	var settings: Set<FileWriteSettings> = [.verifiedWithPin2]
	
	public init(data: Data) {
		self.data = data
	}
	
	public func addStartingTlvData(_ tlvBuilder: TlvBuilder, withEnvironment environment: SessionEnvironment) throws -> TlvBuilder {
		try tlvBuilder.append(.pin2, value: environment.pin2.value)
	}
	
	public func addFinalizingTlvData(_ tlvBuilder: TlvBuilder, withEnvironment environment: SessionEnvironment) throws -> TlvBuilder {
		try tlvBuilder.append(.codeHash, value: data.getSha256())
			.append(.pin2, value: environment.pin2.value)
	}
}
