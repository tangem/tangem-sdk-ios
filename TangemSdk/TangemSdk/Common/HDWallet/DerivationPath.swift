//
//  DerivationPath.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public struct DerivationPath {
    public let rawPath: String
    public let path: [DerivationNode]
    
    /// Parse derivation path.
    /// - Parameter rawPath: Path. E.g. "m/0'/0/1/0"
    public init(rawPath: String) throws {
        let splittedPath = rawPath.lowercased().split(separator: HDWalletConstants.separatorSymbol)
        
        guard splittedPath.count >= 2 else {
            throw HDWalletError.wrongPath
        }
        
        guard splittedPath[0].trim() == HDWalletConstants.masterKeySymbol else {
            throw HDWalletError.wrongPath
        }
        
        var derivationPath: [DerivationNode] = []
        
        for pathItem in splittedPath.suffix(from: 1) {
            let isHardened = pathItem.contains(HDWalletConstants.hardenedSymbol)
            let cleanedPathItem = pathItem.trim().remove(HDWalletConstants.hardenedSymbol)
            guard let index = UInt32(cleanedPathItem) else {
                throw HDWalletError.wrongPath
            }
            
            let node = isHardened ? DerivationNode.hardened(index) : DerivationNode.notHardened(index)
            derivationPath.append(node)
        }
        
        self.init(rawPath: rawPath, path: derivationPath)
    }
    
    public init(path: [DerivationNode]) {
        self.path = path
        
        let description = path.map { $0.pathDescription }.joined(separator: String(HDWalletConstants.separatorSymbol))
        self.rawPath =  "\(HDWalletConstants.masterKeySymbol)\(HDWalletConstants.separatorSymbol)\(description)"
    }
    
    private init(rawPath: String, path: [DerivationNode]) {
        self.rawPath = rawPath
        self.path = path
    }
}

@available(iOS 13.0, *)
extension DerivationPath {
    init(from tlvData: Data) throws {
        guard tlvData.count % 4 == 0 else {
            throw TangemSdkError.decodingFailed("Failed to parse DerivationPath. Data too short.")
        }
        
        let chunks = 0..<tlvData.count/4
        let dataChunks = chunks.map {  tlvData.dropFirst($0 * 4).prefix(4) }
        let path = dataChunks.map { DerivationNode.deserialize(from: $0) }
        self.init(path: path)
    }
    
    func encodeTlv(with tag: TlvTag) -> Tlv {
        let serialized = path.map { $0.serialize() }.joined()
        return Tlv(tag, value: Data(serialized))
    }
}
