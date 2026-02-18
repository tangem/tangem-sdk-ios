//
//  ChangeFileSettingsCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Command for updating file settings
public final class ChangeFileSettingsCommand: Command {
    public var requiresPasscode: Bool { true }
    
    private let fileIndex: Int
    private let newPermissions: FileVisibility
    
    public init(fileIndex: Int, newPermissions: FileVisibility) {
        self.fileIndex = fileIndex
        self.newPermissions = newPermissions
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .filesAvailable {
            return .notSupportedFirmwareVersion
        }
        
        if !card.settings.isFilesAllowed {
            return .filesDisabled
        }
        
        return nil
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        guard let card = environment.card else {
           throw TangemSdkError.missingPreflightRead
        }
        
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.pin, value: environment.accessCode.value)
            .append(.pin2, value: environment.passcode.value)
            .append(.interactionMode, value: FileDataMode.changeFileSettings)
            .append(.fileIndex, value: fileIndex)
            .append(.fileSettings, value: newPermissions.serializeValue(for: card.firmwareVersion))
        
        return CommandApdu(.writeFileData, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SuccessResponse {
        let decoder = try createTlvDecoder(environment: environment, apdu: apdu)
        return SuccessResponse(cardId: try decoder.decode(.cardId))
    }
}
