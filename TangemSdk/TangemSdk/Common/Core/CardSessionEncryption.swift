//
//  CardSessionEncryption.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 13/03/2026.
//

enum CardSessionEncryption {
    /// No encryption at all. Public access or custom encryption implemented by the command itself. COS v8+ cards use this mode for some commands, but old cards use legacy encryption for all commands.
    case none

    /// COS v8+. Old cards use legacy encryption.
    case publicSecureChannel

    /// COS v8+. Old cards use legacy encryption.
    case secureChannel

    /// COS v8+. Old cards use legacy encryption.
    case secureChannelWithPIN
}
