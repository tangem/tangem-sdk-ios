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
    public init?(rawPath: String) {
        let splittedPath = rawPath.lowercased().split(separator: Constants.separatorSymbol)
        
        guard splittedPath.count >= 2 else {
            return nil
        }
        
        guard splittedPath[0].trim() == Constants.masterKeySymbol else {
            return nil
        }
        
        var derivationPath: [DerivationNode] = []
        
        for pathItem in splittedPath.suffix(from: 1) {
            let isHardened = pathItem.contains(Constants.hardenedSymbol)
            let cleanedPathItem = pathItem.trim().remove(Constants.hardenedSymbol)
            guard let index = Int(cleanedPathItem) else { return nil }
            
            let node = isHardened ? DerivationNode.hardened(index) : DerivationNode.notHardened(index)
            derivationPath.append(node)
        }
        
        self.path = derivationPath
        self.rawPath = rawPath
    }
}


@available(iOS 13.0, *)
extension DerivationPath {
    init(from tlvData: Data) {
        let chunks = 0..<tlvData.count/4
        let dataChunks = chunks.map {  tlvData.dropFirst($0 * 4).prefix(4) }
        self.path = dataChunks.map { DerivationNode.deserialize(from: $0) }
        
        let description = self.path.map { $0.pathDescription }.joined(separator: String(Constants.separatorSymbol))
        self.rawPath = "\(Constants.masterKeySymbol)\(Constants.separatorSymbol)\(description)"
    }
    
    func encodeTlv(with tag: TlvTag) -> Tlv {
        let serialized = path.map { $0.serialize() }.joined()
        return Tlv(tag, value: Data(serialized))
    }
}

extension DerivationPath {
    enum Constants {
        static let hardenedSymbol: String = "'"
        static let masterKeySymbol: String = "m"
        static let separatorSymbol: Character = "/"
    }
}
