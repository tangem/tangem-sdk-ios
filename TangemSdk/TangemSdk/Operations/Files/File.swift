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
