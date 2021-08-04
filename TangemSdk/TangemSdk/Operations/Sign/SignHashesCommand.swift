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
    public var preflightReadMode: PreflightReadMode { .readWallet(publicKey: walletPublicKey) }

    private let walletPublicKey: Data
    private let hashes: [Data]
    private let hdPath: DerivationPath?

    /// Default initializer
    /// - Parameters:
    ///   - hashes: Array of transaction hashes. It can be from one or up to ten hashes of the same length.
    ///   - walletPublicKey: Public key of the wallet, using for sign.
    ///   - hdPath: Derivation path of the wallet. Optional
    init(hashes: [Data], walletPublicKey: Data, hdPath: DerivationPath? = nil) {
        self.hashes = hashes
        self.walletPublicKey = walletPublicKey
        self.hdPath = hdPath
    }

    deinit {
        Log.debug("SignHashesCommand deinit")
    }

    public func run(in session: CardSession, completion: @escaping CompletionResult<SignHashesResponse>) {
        let signCommand = SignCommand(hashes: hashes, walletPublicKey: walletPublicKey, hdPath: hdPath)
        signCommand.run(in: session, completion: completion)
    }
}
