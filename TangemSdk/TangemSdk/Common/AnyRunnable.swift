//
//  AnyRunnable.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 17.05.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Type erased CardSessionRunnable
public class AnyRunnable: CardSessionRunnable {
    public typealias CommandResponse = AnyResponse
    
    public var preflightReadMode: PreflightReadMode = .fullCardRead
    
    private let runClosure: (_ session: CardSession, _ completion: @escaping CompletionResult<AnyResponse>) -> Void

    init<T: CardSessionRunnable>(_ runnable: T) {
        preflightReadMode = runnable.preflightReadMode
        
        runClosure = { session, compl in
            runnable.run(in: session) { res in
                switch res {
                case .success(let response):
                    compl(.success(AnyResponse(response)))
                case .failure(let err):
                    compl(.failure(err))
                }
            }
        }
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<AnyResponse>) {
        runClosure(session, completion)
    }
}

public struct AnyResponse: JSONStringConvertible {
    let response: JSONStringConvertible
    
    public init<T: JSONStringConvertible>(_ response: T) {
        self.response = response
    }
    
    public func encode(to encoder: Encoder) throws {
        try response.encode(to: encoder)
    }
}
