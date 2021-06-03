////
////  ScanTask.swift
////  TangemSdk
////
////  Created by Alexander Osokin on 03/10/2019.
////  Copyright © 2019 Tangem AG. All rights reserved.
////
//
//import Foundation
//
///// Task that allows to create wallet at Tangem card and verify its private key.
///// It performs `CreateWallet` and `CheckWalletCommand`,  subsequently.
/////
///// Initializer contain wallet configuration settings and wallet index pointer at which  index wallet should be created. If index not provided task
///// attempt to create wallet at any empty index, until success or reach max index
///// - Note: `WalletConfig` and `WalletIndex` available for cards with COS v.4.0 and higher
/////
///// * `Config`: if not set task will create wallet with settings that was specified in card data while personalization
///// * `Wallet Index`: If not provided task will attempt to create wallet on default index. If failed - task will keep trying to create
//public final class CreateWalletTask: CardSessionRunnable {
//    public typealias Response = CreateWalletResponse
//	
//	public var walletIndex: WalletIndex? { nil }
//	
//	private let config: WalletConfig?
//
//	/// - Parameters:
//	///   - config: Specified wallet settings including blockchain name.
//	///   - walletIndex: Index at which new wallet will be created.
//	public init(config: WalletConfig? = nil) {
//		self.config = config
//	}
//	
//	deinit {
//        Log.debug("CreateWalletTask deinit")
//	}
//    
//    public func run(in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
//		guard
//			var card = session.environment.card,
//			var curve = card.defaultCurve
//		else {
//			completion(.failure(.cardError))
//			return
//		}
//		
//		// This check need to exclude cases when WalletConfig parameters is added but card has COS lower than 4.0
//		if session.environment.card?.firmwareVersion >= FirmwareConstraints.AvailabilityVersions.walletData {
//            if let configCurve = config?.curveId {
//				curve = configCurve
//			}
//		}
//
//        guard let emptyWallet = card.wallets.first(where: { $0.status == .empty }) else {
//            completion(.failure(.maxNumberOfWalletsCreated))
//            return
//        }
//        
//        Log.debug("------ Found empty wallet \(emptyWallet). Attempting to create wallet ---------")
//        
//        CreateWalletCommand(config: config, walletIndex: emptyWallet.index).run(in: session) { (result) in
//            switch result {
//            case .success(let response):
//                card.status = response.status
//                let settings = card.settingsMask
//                //todo: move to command
//                card.updateWallet(at: emptyWallet.intIndex, with: CardWallet(from: response, with: curve, settings: settings))
//                session.environment.card = card
//                completion(.success(response))
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
//}
