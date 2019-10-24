//
//  SingleCommandtask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public final class SingleCommandTask<T: CommandSerializer>: Task<T.CommandResponse> {
    private let command: T
    
    public init(_ command: T) {
        self.command = command
    }
    
    override public func onRun(environment: CardEnvironment, callback: @escaping (TaskEvent<T.CommandResponse>) -> Void) {
        sendCommand(command, environment: environment, callback: callback)
    }
}
