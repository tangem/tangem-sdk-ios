//
//  Handlers.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 21.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
class ScanHandler: JSONRPCHandler {
    var method: String { "SCAN" }
    var requiresCardId: Bool { false }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let command = ScanTask()
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class SignHashesHandler: JSONRPCHandler {
    var method: String { "SIGN_HASHES" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletPublicKey: Data = try parameters.value(for: "walletPublicKey")
        let hashes: [Data] = try parameters.value(for: "hashes")
        
        let hdRawPath: String? = try parameters.value(for: "hdPath")
        let hdPath: DerivationPath? = try hdRawPath.map{ try DerivationPath(rawPath: $0) }
        
        let command = SignHashesCommand(hashes: hashes,
                                        walletPublicKey: walletPublicKey,
                                        hdPath: hdPath)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class SignHashHandler: JSONRPCHandler {
    var method: String { "SIGN_HASH" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletPublicKey: Data = try parameters.value(for: "walletPublicKey")
        let hash: Data = try parameters.value(for: "hash")
        
        let hdRawPath: String? = try parameters.value(for: "hdPath")
        let hdPath: DerivationPath? = try hdRawPath.map{ try DerivationPath(rawPath: $0) }
        
        let command = SignHashCommand(hash: hash,
                                      walletPublicKey: walletPublicKey,
                                      hdPath: hdPath)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class CreateWalletHandler: JSONRPCHandler {
    var method: String { "CREATE_WALLET" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let curve: EllipticCurve = try parameters.value(for: "curve")
        let command = CreateWalletCommand(curve: curve)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class PurgeWalletHandler: JSONRPCHandler {
    var method: String { "PURGE_WALLET" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletPublicKey: Data = try parameters.value(for: "walletPublicKey")
        let command = PurgeWalletCommand(publicKey: walletPublicKey)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class PersonalizeHandler: JSONRPCHandler {
    var method: String { "PERSONALIZE" }
    
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

@available(iOS 13.0, *)
class DepersonalizeHandler: JSONRPCHandler {
    var method: String { "DEPERSONALIZE" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let command = DepersonalizeCommand()
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class SetAccessCodeHandler: JSONRPCHandler {
    var method: String { "SET_ACCESSCODE" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let accessCode: String? = try parameters.value(for: "accessCode")
        let command = SetUserCodeCommand(accessCode: accessCode)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class SetPasscodeHandler: JSONRPCHandler {
    var method: String { "SET_PASSCODE" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let passcode: String? = try parameters.value(for: "passcode")
        let command = SetUserCodeCommand(passcode: passcode)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class ResetUserCodesHandler: JSONRPCHandler {
    var method: String { "RESET_USERCODES" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        return SetUserCodeCommand.resetUserCodes.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class PreflightReadHandler: JSONRPCHandler {
    var method: String { "PREFLIGHT_READ" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let cardId: String? = try parameters.value(for: "cardId")
        let mode: PreflightReadMode = try parameters.value(for: "readMode")
        let command = PreflightReadTask(readMode: mode, cardId: cardId)
        return command.eraseToAnyRunnable()
    }
}

//@available(iOS 13.0, *)
//class ReadFilesHandler: JSONRPCHandler {
//    var method: String { "READ_FILES" }
//    
//    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
//        let readPrivateFiles: Bool? = try parameters.value(for: "readPrivateFiles")
//        let indices: [Int]? = try parameters.value(for: "indices")
//        
//        let command = ReadFilesTask(readPrivateFiles: readPrivateFiles ?? false,
//                                    indices: indices)
//        return command.eraseToAnyRunnable()
//    }
//}

@available(iOS 13.0, *)
class WriteFilesHandler: JSONRPCHandler {
    var method: String { "WRITE_FILES" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        var files: [DataToWrite] = []
        
        guard let filesArray = parameters["files"] as? [Any] else {
            throw JSONRPCError(.parseError, data: JSONRPCErrorData(.parseError, message: "Failed to parse files array"))
        }
        
        let overwriteAllFiles: Bool? = try parameters.value(for: "overwriteAllFiles")
        
        for file in filesArray {
            let jsonData = try JSONSerialization.data(withJSONObject: file)
            
            if let decoded = try? JSONDecoder.tangemSdkDecoder.decode(FileDataProtectedBySignature.self, from: jsonData) {
                files.append(decoded)
            } else if let decoded = try? JSONDecoder.tangemSdkDecoder.decode(FileDataProtectedByPasscode.self, from: jsonData) {
                files.append(decoded)
            } else {
                throw JSONRPCError(.parseError, data: JSONRPCErrorData(.parseError, message: "Failed to parse files array"))
            }
        }

        let command = WriteFilesTask(files: files, overwriteAllFiles: overwriteAllFiles ?? false)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class DeleteFilesHandler: JSONRPCHandler {
    var method: String { "DELETE_FILES" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let indices: [Int]? = try parameters.value(for: "filesToDelete")
        let command = DeleteFilesTask(filesToDelete: indices)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class ChangeFileSettingsHandler: JSONRPCHandler {
    var method: String { "CHANGE_FILE_SETTINGS" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let changes: [FileSettingsChange] = try parameters.value(for: "changes")
        let command = ChangeFileSettingsTask(changes: changes)
        return command.eraseToAnyRunnable()
    }
}
