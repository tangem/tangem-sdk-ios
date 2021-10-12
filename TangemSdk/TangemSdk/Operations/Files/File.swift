//
//  File.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/6/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13, *)
public struct File: JSONStringConvertible {
    public let fileData: Data
    public let fileIndex: Int
    public let fileSettings: FileSettings?
}

@available (iOS 13, *)
extension File {
    init(response: ReadFileResponse) {
        fileIndex = response.fileIndex
        fileSettings = response.fileSettings
        fileData = response.fileData
    }
}

@available(iOS 13.0, *)
public struct NamedFile {
    public let name: String
    public let payload: Data
    
    public init(name: String, payload: Data) {
        self.name = name
        self.payload = payload
    }
    
    public init? (tlvData: Data) throws {
        guard let tlv = Tlv.deserialize(tlvData) else {
           return nil
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        name = try decoder.decode(.fileTypeName)
        payload = try decoder.decode(.fileData)
    }
    
    public func serialize() throws -> Data {
        let tlvBuilder = try TlvBuilder()
            .append(.fileTypeName, value: name)
            .append(.fileData, value: payload)
        
        return tlvBuilder.serialize()
    }
}

@available (iOS 13.0, *)
public enum FileToWrite: Decodable {
    case byUser(data: Data, fileVisibility: FileVisibility?, walletPublicKey: Data?)
    case byFileOwner(data: Data, startingSignature: Data, finalizingSignature: Data, counter: Int,
                     fileVisibility: FileVisibility?, walletPublicKey: Data?)
    
    public init(from decoder: Decoder) throws {
        do {
            let file = try OwnerFile(from: decoder)
            self = .byFileOwner(data: file.data,
                                startingSignature: file.startingSignature,
                                finalizingSignature: file.finalizingSignature,
                                counter: file.counter,
                                fileVisibility: file.fileVisibility,
                                walletPublicKey: file.walletPublicKey)
        } catch {
            let file = try UserFile(from: decoder)
            self = .byUser(data: file.data,
                           fileVisibility: file.fileVisibility,
                           walletPublicKey: file.walletPublicKey)
        }
    }
    
    private struct UserFile: Decodable {
        let data: Data
        let fileVisibility: FileVisibility?
        let walletPublicKey: Data?
    }
    
    private struct OwnerFile: Decodable {
        let data: Data
        let startingSignature: Data
        let finalizingSignature: Data
        let counter: Int
        let fileVisibility: FileVisibility?
        let walletPublicKey: Data?
    }
}
