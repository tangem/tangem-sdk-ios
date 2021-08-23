//
//  DataToWrite.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/7/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
public protocol DataToWrite: FirmwareRestrictable {
	var data: Data { get }
	var requiredPasscode: Bool { get }
	func addStartingTlvData(_ tlvBuilder: TlvBuilder, withEnvironment environment: SessionEnvironment) throws ->  TlvBuilder
	func addFinalizingTlvData(_ tlvBuilder: TlvBuilder, withEnvironment environment: SessionEnvironment) throws -> TlvBuilder
}

/// Use this type when protecting data with issuer data signature.
/// - Note: To generate starting and finalizing signatures use `FileHashHelper`
@available (iOS 13.0, *)
public struct FileDataProtectedBySignature: DataToWrite, Decodable {
	public let data: Data
	
	public var requiredPasscode: Bool { false }
	public var minFirmwareVersion: FirmwareVersion { settings.minFirmwareVersion() }
	public var maxFirmwareVersion: FirmwareVersion { settings.maxFirmwareVersion() }
	
	let startingSignature: Data
	let finalizingSignature: Data
	let counter: Int
    
    private var settings: Set<FileWriteSettings> { [.none] }
    
	public init(data: Data, startingSignature: Data, finalizingSignature: Data, counter: Int) {
		self.data = data
		self.startingSignature = startingSignature
		self.finalizingSignature = finalizingSignature
		self.counter = counter
	}
	
	public func addStartingTlvData(_ tlvBuilder: TlvBuilder, withEnvironment environment: SessionEnvironment) throws -> TlvBuilder {
		try tlvBuilder.append(.issuerDataSignature, value: startingSignature)
			.append(.issuerDataCounter, value: counter)
	}
	
	public func addFinalizingTlvData(_ tlvBuilder: TlvBuilder, withEnvironment environment: SessionEnvironment) throws -> TlvBuilder {
		try tlvBuilder.append(.issuerDataSignature, value: finalizingSignature)
	}
	
}

/// Use this type when protecting data with passcode
@available (iOS 13.0, *)
public struct FileDataProtectedByPasscode: DataToWrite, Decodable {
	public let data: Data
	
	public var requiredPasscode: Bool { true }
	public var minFirmwareVersion: FirmwareVersion { settings.minFirmwareVersion() }
	public var maxFirmwareVersion: FirmwareVersion { settings.maxFirmwareVersion() }
	
    private var settings: Set<FileWriteSettings> { [.verifiedWithPasscode] }
	
	public init(data: Data) {
		self.data = data
	}

	public func addStartingTlvData(_ tlvBuilder: TlvBuilder, withEnvironment environment: SessionEnvironment) throws -> TlvBuilder {
		try tlvBuilder.append(.pin2, value: environment.passcode.value)
	}
	
	public func addFinalizingTlvData(_ tlvBuilder: TlvBuilder, withEnvironment environment: SessionEnvironment) throws -> TlvBuilder {
		try tlvBuilder.append(.codeHash, value: data.getSha256())
			.append(.pin2, value: environment.passcode.value)
	}
}
