//
//  SignHashesTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 21.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
public typealias SignHashesResponse = SignResponse

@available(iOS 13.0, *)
public final class SignHashesCommand: CardSessionRunnable {
    private let walletIndex: WalletIndex
    private let hashes: [Data]
    private let derivationPath: DerivationPath?

    /// Default initializer
    /// - Parameters:
    ///   - hashes: Array of transaction hashes. It can be from one or up to ten hashes of the same length.
    ///   - walletIndex: Index of the wallet, using for sign.
    ///   - derivationPath: Derivation path of the wallet. Optional. COS v. 4.28 and higher,
    public init(hashes: [Data], walletIndex: WalletIndex, derivationPath: DerivationPath? = nil) {
        self.hashes = hashes
        self.walletIndex = walletIndex
        self.derivationPath = derivationPath
    }

    deinit {
        Log.debug("SignHashesCommand deinit")
    }

    public func run(in session: CardSession, completion: @escaping CompletionResult<SignHashesResponse>) {
        let signCommand = SignCommand(hashes: hashes, walletIndex: walletIndex, derivationPath: derivationPath)
        signCommand.run(in: session, completion: completion)
    }
}
