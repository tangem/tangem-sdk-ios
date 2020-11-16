//
//  ScanTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Task that allows to create wallet at Tangem card and verify its private key.
/// It performs `CreateWallet` and `CheckWalletCommand`,  subsequently.
///
/// Initializer contain wallet configuration settings and wallet index pointer at which  index wallet should be created. If index not provided task
/// attempt to create wallet at any empty index, until success or reach max index
/// - Note: `WalletConfig` and `WalletPointer` available for cards with COS v.4.0 and higher
///
/// * `Config`: if not set task will create wallet with settings that was specified in card data while personalization
/// * `Wallet pointer`: If not provided task will attempt to create wallet on default index. If failed - task will keep trying to create
@available(iOS 13.0, *)
public final class CreateWalletTask: CardSessionRunnable, WalletPointable {
    public typealias CommandResponse = CreateWalletResponse
    
    public var requiresPin2: Bool {
        return true
    }
	
	public var pointer: WalletPointer? {
		indexPointer
	}
	
	private let config: WalletConfig?
	
	private var indexPointer: WalletIndexPointer?
	private var firstAttemptWalletIndex: Int?
	private var shouldCreateAtAnyIndex: Bool = false

	/// - Parameters:
	///   - config: Specified wallet settings including blockchain name.
	///   - walletPointer: Index at which new wallet will be created.
	public init(config: WalletConfig?, walletPointer: WalletIndexPointer?) {
		self.config = config
		self.indexPointer = walletPointer
	}
	
	deinit {
		print ("CreateWalletTask deinit")
	}
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
		guard
			let card = session.environment.card,
			var curve = card.curve
		else {
			completion(.failure(.cardError))
			return
		}
		
		// This check need to exclude cases when WalletConfig parameters is added but card has COS lower than 4.0
		if session.environment.card?.isCosGreaterOrEqual(than: FirmwareConstraints.AvailabilityVersions.walletData) ?? false {
			
			if let config = config {
				curve = config.curveId
			}
			
			shouldCreateAtAnyIndex = indexPointer == nil
		}

		createWallet(in: session, forCard: card, at: indexPointer ?? WalletIndexPointer(index: 0), with: curve, completion: completion)
    }
	
	private func createWallet(in session: CardSession, forCard card: Card, at index: WalletIndexPointer, with curve: EllipticCurve, completion: @escaping CompletionResult<CreateWalletResponse>) {
		
		print("Attempt to create wallet at index: \(index)")
		let command = CreateWalletCommand(config: config, walletPointer: index)
		command.run(in: session) { result in
			switch result {
			case .success(let createWalletResponse):
				if createWalletResponse.status == .loaded {
					CheckWalletCommand(curve: curve, publicKey: createWalletResponse.walletPublicKey, walletPointer: self.pointer).run(in: session) { checkWalletResult in
						switch checkWalletResult {
						case .success(_):
							completion(.success(createWalletResponse))
						case .failure(let error):
							completion(.failure(error))
						}
					}
					
				} else {
					completion(.failure(.unknownError))
				}
			case .failure(let error):
				if self.shouldCreateAtAnyIndex {
					print("Failure while creating wallet. \(error)")
					switch error {
					case .alreadyCreated, .cardIsPurged, .invalidState:
						if let nextIndex = self.updateWalletPointerToNext(currentPointer: index, walletsCount: card.walletsCount) {
							self.indexPointer = nextIndex
							self.createWallet(in: session, forCard: card, at: nextIndex, with: curve, completion: completion)
							return
						}
						completion(.failure(TangemSdkError.maxNumberOfWalletsCreated))
						return
					default:
						print("Default error case while creating wallet.", error)
						break
					}
				}
				
				completion(.failure(error))
			}
		}
	}
	
	private func updateWalletPointerToNext(currentPointer: WalletIndexPointer?, walletsCount: Int?) -> WalletIndexPointer? {
		guard
			let currentIndex = currentPointer?.index,
			let walletsCount = walletsCount
		else { return nil }
		
		var isFirstAttempt = false
		if firstAttemptWalletIndex == nil {
			// Needs for prevent repeating first create wallet attempt
			firstAttemptWalletIndex = currentIndex
			isFirstAttempt = true
		}
		
		var newIndex: Int
		if isFirstAttempt, currentIndex != 0 {
			// This route handle case when first attempt to create wallet was not at the first index
			newIndex = 0
		} else {
			// Take next index
			newIndex = currentIndex + 1
			// If index match with first attempt index, move to next
			newIndex += firstAttemptWalletIndex == newIndex ? 1 : 0
		}
		
		if newIndex >= walletsCount { return nil }
		
		return WalletIndexPointer(index: newIndex)
	}
}
