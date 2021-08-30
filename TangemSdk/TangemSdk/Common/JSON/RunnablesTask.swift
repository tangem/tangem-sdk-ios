//
//  RunnablesTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 30.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
typealias RunnablesTaskResponse = [Result<AnyJSONRPCResponse, TangemSdkError>]

@available(iOS 13.0, *)
final class RunnablesTask: CardSessionRunnable {
    private let runnables: [AnyJSONRPCRunnable]
    private var responses: RunnablesTaskResponse = .init()
    
    init(runnables: [AnyJSONRPCRunnable]) {
        self.runnables = runnables
    }
    
    deinit {
        Log.debug("RunnablesTask deinit")
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<RunnablesTaskResponse>) {
        runRunnable(in: session, with: 0, completion: completion)
    }
    
    private func runRunnable(in session: CardSession, with index: Int, completion: @escaping CompletionResult<RunnablesTaskResponse>) {
        if index >= runnables.count {
            completion(.success(responses))
            return
        }
        
        runnables[index].run(in: session) {
            self.responses.append($0)
            self.runRunnable(in: session, with: index + 1, completion: completion)
        }
    }
}
