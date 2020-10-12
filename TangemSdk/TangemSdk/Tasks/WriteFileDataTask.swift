//
//  WriteFileDataTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/7/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
public final class WriteFileDataTask: CardSessionRunnable {
	
	public init(file: DataToWrite, issuerKeys: KeyPair, fileDataCounter: Int? = nil) {
		self.file = file
		self.issuerKeys = issuerKeys
		self.fileDataCounter = fileDataCounter
	}
	
	public var requiresPin2: Bool { file.settings.contains(.verifiedWithPin2) }
	
	private let file: DataToWrite
	private let issuerKeys: KeyPair
	
	private var fileDataCounter: Int?
	
	public func run(in session: CardSession, completion: @escaping CompletionResult<WriteFileDataResponse>) {
		if let fileDataCounter = fileDataCounter, let cardId = session.environment.card?.cardId {
			performWriteCommand(in: session, counter: fileDataCounter, cardId: cardId, completion: completion)
			return
		}
		ReadFileDataCommand(fileIndex: 0, readPrivateFiles: false).run(in: session) { (result) in
			switch result {
			case .success(let response):
				let counter = (response.fileDataCounter ?? 0)
				self.performWriteCommand(in: session, counter: counter, cardId: response.cardId, completion: completion)
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	private func performWriteCommand(in session: CardSession, counter: Int, cardId: String, completion: @escaping CompletionResult<WriteFileDataResponse>) {
		let newCounter = counter + 1
		guard
			let startingSignature = getStartingSignature(data: file.data, counter: newCounter, cardId: cardId),
			let finalizingSignature = getFinalizingSignature(data: file.data, counter: newCounter, cardId: cardId)
		else {
			completion(.failure(.cryptoUtilsError))
			return
		}
		WriteFileDataCommand(data: file.data, startingSignature: startingSignature, finalizingSignature: finalizingSignature, dataCounter: newCounter, issuerPublicKey: issuerKeys.publicKey)
			.run(in: session) { (result) in
				switch result {
				case .success(let response):
					completion(.success(response))
				case .failure(let error):
					completion(.failure(error))
				}
			}
	}
	
	// TODO: Remove sign logic from Card SDK
	private func getStartingSignature(data: Data, counter: Int, cardId: String) -> Data? {
		FileSignatureGenerator.generateStartingSignature(forCardWith: cardId, data: data, fileCounter: counter)
			.sign(privateKey: issuerKeys.privateKey)
	}
	
	private func getFinalizingSignature(data: Data, counter: Int, cardId: String) -> Data? {
		FileSignatureGenerator.generateFinalizingSignature(forCardWith: cardId, data: data, fileCounter: counter)
			.sign(privateKey: issuerKeys.privateKey)
	}
	
}
