//
//  SignCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public struct SignResponse: TlvMappable {
    public let cardId: String
    public let signature: Data
    public let walletRemainingSignatures: Int
    public let walletSignedHashes: Int
    
    public init(from tlv: [Tlv]) throws {
        let mapper = TlvMapper(tlv: tlv)
        do {
            cardId = try mapper.map(.cardId)
            signature = try mapper.map(.walletSignature)
            walletRemainingSignatures = try mapper.map(.walletRemainingSignatures)
            walletSignedHashes = try mapper.map(.walletSignedHashes)
        }
        catch {
            throw error
        }
    }
}

@available(iOS 13.0, *)
final class SignHashesCommand: CommandSerializer {
    typealias CommandResponse = SignResponse
    
    private let hashSize: Int
    private let dataToSign: Data
    private let cardId: String
    
    public init(hashes: [Data], cardId: String) throws {
        guard hashes.count > 0 else {
            throw TaskError.emptyHashes
        }
        
        guard hashes.count <= 10 else {
            throw TaskError.tooMuchHashesInOneTransaction
        }
        
        hashSize = hashes.first!.count
        var flattenHashes = [Byte]()
        for hash in hashes {
            guard hash.count == hashSize else {
                throw TaskError.hashSizeMustBeEqual
            }
            
            flattenHashes.append(contentsOf: hash.bytes)
        }
        self.cardId = cardId
        dataToSign = Data(flattenHashes)
    }
    
    func serialize(with environment: CardEnvironment) -> CommandApdu {
        var tlvData = [Tlv(.pin, value: environment.pin1.sha256()),
                       Tlv(.pin2, value: environment.pin2.sha256()),
                       Tlv(.cardId, value: Data(hex: cardId)),
                       Tlv(.transactionOutHashSize, value: hashSize.byte),
                       Tlv(.transactionOutHash, value: dataToSign)]
        
        if let keys = environment.terminalKeys,
            let signedData = CryptoUtils.sign(dataToSign.sha256(), with: keys.privateKey) {
            tlvData.append(Tlv(.terminalTransactionSignature, value: signedData))
            tlvData.append(Tlv(.terminalPublicKey, value: keys.publicKey))
        }
        
        let cApdu = CommandApdu(.sign, tlv: tlvData)
        return cApdu
    }
}
