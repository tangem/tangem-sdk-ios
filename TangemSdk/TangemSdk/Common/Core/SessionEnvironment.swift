//
//  SessionEnvironment.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Contains data relating to a Tangem card. It is used in constructing all the commands,
/// and commands can return modified `SessionEnvironment`.
public struct SessionEnvironment {
    /// Current card, read by preflight `Read` command
    public internal(set) var card: Card? = nil
    
    let config: Config
    
    weak var terminalKeysService: TerminalKeysService?
    
    var encryptionMode: EncryptionMode = .none
    
    var encryptionKey: Data? = nil
    
    var cvc: Data? = nil //todo: remove
    
    var pin1: PinCode = PinCode(.pin1)
    
    var pin2: PinCode = PinCode(.pin2)
    
    var legacyMode: Bool { config.legacyMode ?? NfcUtils.isPoorNfcQualityDevice }
    
    /// Keys for Linked Terminal feature
    var terminalKeys: KeyPair? {
        if config.linkedTerminal ?? !NfcUtils.isPoorNfcQualityDevice {
            return terminalKeysService?.keys
        }
        
        return nil
    }
}
