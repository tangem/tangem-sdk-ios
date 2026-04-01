//
//  SessionEnvironment.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Contains data relating to a Tangem card. It is used in constructing all the commands,
/// and commands can return modified `SessionEnvironment`.
public struct SessionEnvironment {
    /// Current card, read by preflight `Read` command
    public internal(set) var card: Card?

    /// Current card's wallet data, read by preflight `Read` command
    public internal(set) var walletData: WalletData?

    public internal(set) var config: Config

    weak var terminalKeysService: TerminalKeysService?

    var encryptionMode: EncryptionMode = .none

    var encryptionKey: Data?

    var currentSecurityDelay: Float?

    /// COS v8+
    var cardAccessTokens: CardAccessTokens?

    var accessCode: UserCode = .init(.accessCode)

    var passcode: UserCode = .init(.passcode)

    var legacyMode: Bool { config.legacyMode ?? NFCUtils.isPoorNfcQualityDevice }

    /// Keys for Linked Terminal feature
    var terminalKeys: KeyPair? {
        if config.linkedTerminal ?? !NFCUtils.isPoorNfcQualityDevice {
            return terminalKeysService?.keys
        }

        return nil
    }

    init(config: Config = Config(), terminalKeysService: TerminalKeysService? = nil) {
        self.config = config
        self.terminalKeysService = terminalKeysService
    }

    mutating func reset() {
        encryptionKey?.zeroOut()
        encryptionKey = nil
        cardAccessTokens = nil
        accessCode = .init(.accessCode)
        passcode = .init(.passcode)
    }
}
