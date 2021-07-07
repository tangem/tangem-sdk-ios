//
//  Handlers.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 21.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class ScanHandler: JSONRPCHandler {
    var method: String { "SCAN" }
    var requiresCardId: Bool { false }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let command = ScanTask()
        return command.eraseToAnyRunnable()
    }
}

class SignHashesHandler: JSONRPCHandler {
    var method: String { "SIGN_HASHES" }
    var requiresCardId: Bool { true }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletPublicKey: Data = try parameters.value(for: "walletPublicKey")
        let hashes: [Data] = try parameters.value(for: "hashes")
        let command = SignHashesCommand(hashes: hashes,
                                  walletPublicKey: walletPublicKey)
        return command.eraseToAnyRunnable()
    }
}

class SignHashHandler: JSONRPCHandler {
    var method: String { "SIGN_HASH" }
    var requiresCardId: Bool { true }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletPublicKey: Data = try parameters.value(for: "walletPublicKey")
        let hash: Data = try parameters.value(for: "hash")
        
        let command = SignHashCommand(hash: hash,
                                  walletPublicKey: walletPublicKey)
        return command.eraseToAnyRunnable()
    }
}

class CreateWalletHandler: JSONRPCHandler {
    var method: String { "CREATE_WALLET" }
    var requiresCardId: Bool { true }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let curve: EllipticCurve = try parameters.value(for: "curve")
        let isPermanent: Bool = try parameters.value(for: "isPermanent")
        let command = CreateWalletCommand(curve: curve, isPermanent: isPermanent)
        return command.eraseToAnyRunnable()
    }
}

class PurgeWalletHandler: JSONRPCHandler {
    var method: String { "PURGE_WALLET" }
    var requiresCardId: Bool { true }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletPublicKey: Data = try parameters.value(for: "walletPublicKey")
        let command = PurgeWalletCommand(publicKey: walletPublicKey)
        return command.eraseToAnyRunnable()
    }
}

class PersonalizeHandler: JSONRPCHandler {
    var method: String { "PERSONALIZE" }
    
    var requiresCardId: Bool { false }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let config: CardConfig = try parameters.value(for: "config")
        let issuer: Issuer = try parameters.value(for: "issuer")
        let manufacturer: Manufacturer = try parameters.value(for: "manufacturer")
        let acquirer: Acquirer = try parameters.value(for: "acquirer")
        
        let command = PersonalizeCommand(config: config,
                                         issuer: issuer,
                                         manufacturer: manufacturer,
                                         acquirer: acquirer)
        return command.eraseToAnyRunnable()
    }
}

class DepersonalizeHandler: JSONRPCHandler {
    var method: String { "DEPERSONALIZE" }
    var requiresCardId: Bool { false }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let command = DepersonalizeCommand()
        return command.eraseToAnyRunnable()
    }
}

class SetAccessCodeHandler: JSONRPCHandler {
    var method: String { "SET_ACCESSCODE" }
    
    var requiresCardId: Bool { false }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let stringCode: String? = try parameters.value(for: "accessCode")
        let code: SetPinCommand.UserCode = stringCode.map { .value($0) } ?? .request
        let command = SetPinCommand(accessCode: code)
        return command.eraseToAnyRunnable()
    }
}

class SetPasscodeHandler: JSONRPCHandler {
    var method: String { "SET_PASSCODE" }
    
    var requiresCardId: Bool { false }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let stringCode: String? = try parameters.value(for: "passcode")
        let code: SetPinCommand.UserCode = stringCode.map { .value($0) } ?? .request
        let command = SetPinCommand(passcode: code)
        return command.eraseToAnyRunnable()
    }
}

/// Runs PreflightReadTask in `fullCardRead` mode
class PreflightReadHandler: JSONRPCHandler {
    var method: String { "PREFLIGHT_READ" }
    
    var requiresCardId: Bool { false }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let cardId: String? = try parameters.value(for: "cardId")
        let mode: PreflightReadMode = try parameters.value(for: "readMode")
        let command = PreflightReadTask(readMode: mode, cardId: cardId)
        return command.eraseToAnyRunnable()
    }
}
