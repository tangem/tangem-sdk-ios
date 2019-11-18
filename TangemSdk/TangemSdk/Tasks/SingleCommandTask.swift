//
//  SingleCommandtask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/**
* Allows to perform a single command
* `TCommand` -  a command that will be performed.
*/
@available(iOS 13.0, *)
public final class SingleCommandTask<TCommand: CommandSerializer>: Task<TCommand.CommandResponse> {
    private let command: TCommand
    
    public init(_ command: TCommand) {
        self.command = command
    }
    
    override public func onRun(environment: CardEnvironment, callback: @escaping (TaskEvent<TCommand.CommandResponse>) -> Void) {
        sendCommand(command, environment: environment) { result in
            switch result {
            case .success(let commandResponse):
                self.delegate?.showAlertMessage(Localization.nfcAlertDefaultDone)
                self.reader.stopSession()
                callback(.event(commandResponse))
                callback(.completion(nil))
                self.reader.stopSession()
            case .failure(let error):
                self.reader.stopSession(errorMessage: error.localizedDescription)
                callback(.completion(error))
            }
        }
    }
}
