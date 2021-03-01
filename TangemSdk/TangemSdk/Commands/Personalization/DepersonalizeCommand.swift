//
//  DepersonalizeCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 22.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct DepersonalizeResponse: JSONStringConvertible {
    let success: Bool
}

/**
* Command available on SDK cards only
* This command resets card to initial state,
* erasing all data written during personalization and usage.
*/
public class DepersonalizeCommand: Command {
    public typealias CommandResponse = DepersonalizeResponse
    
    var needPreflightRead: Bool {
        return false
    }
    
    public init() {}
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        return CommandApdu(.depersonalize, tlv: Data())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> DepersonalizeResponse {
        return DepersonalizeResponse(success: true)
    }
}
