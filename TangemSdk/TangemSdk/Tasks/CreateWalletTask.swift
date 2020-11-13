//
//  ScanTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Task that allows to read Tangem card and verify its private key.
/// It performs `CreateWallet` and `CheckWalletCommand`,  subsequently.
@available(iOS 13.0, *)
public final class CreateWalletTask: CardSessionRunnable, WalletPointable {
    public typealias CommandResponse = CreateWalletResponse
	
	public init(walletPointer: WalletIndexPointer?) {
		self.indexPointer = walletPointer
	}
	
    deinit {
        print ("CreateWalletTask deinit")
    }
    
    public var requiresPin2: Bool {
        return true
    }
	
	public var pointer: WalletPointer? {
		indexPointer
	}
	
	private var indexPointer: WalletIndexPointer?
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
        guard let curve = session.environment.card?.curve else {
            completion(.failure(.cardError))
            return
        }

		let command = CreateWalletCommand(walletPointer: indexPointer)
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
                completion(.failure(error))
            }
        }
    }
}
