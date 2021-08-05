//
//  DerivationPath.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// BIP32 derivation Path
public struct DerivationPath {
    public let rawPath: String
    public let nodes: [DerivationNode]
    
    /// Parse derivation path.
    /// - Parameter rawPath: Path. E.g. "m/0'/0/1/0"
    public init(rawPath: String) throws {
        let splittedPath = rawPath.lowercased().split(separator: BIP32.Constants.separatorSymbol)
        
        guard splittedPath.count >= 2 else {
            throw HDWalletError.wrongPath
        }
        
        guard splittedPath[0].trim() == BIP32.Constants.masterKeySymbol else {
            throw HDWalletError.wrongPath
        }
        
        var derivationPath: [DerivationNode] = []
        
        for pathItem in splittedPath.suffix(from: 1) {
            let isHardened = pathItem.contains(BIP32.Constants.hardenedSymbol)
            let cleanedPathItem = pathItem.trim().remove(BIP32.Constants.hardenedSymbol)
            guard let index = UInt32(cleanedPathItem) else {
                throw HDWalletError.wrongPath
            }
            
            let node = isHardened ? DerivationNode.hardened(index) : DerivationNode.notHardened(index)
            derivationPath.append(node)
        }
        
        self.init(rawPath: rawPath, nodes: derivationPath)
    }
    
    public init(nodes: [DerivationNode]) {
        self.nodes = nodes
        
        let description = nodes.map { $0.pathDescription }.joined(separator: String(BIP32.Constants.separatorSymbol))
        self.rawPath =  "\(BIP32.Constants.masterKeySymbol)\(BIP32.Constants.separatorSymbol)\(description)"
    }
    
    private init(rawPath: String, nodes: [DerivationNode]) {
        self.rawPath = rawPath
        self.nodes = nodes
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
        self.init(nodes: path)
    }
    
    func encodeTlv(with tag: TlvTag) -> Tlv {
        let serialized = nodes.map { $0.serialize() }.joined()
        return Tlv(tag, value: Data(serialized))
    }
}
