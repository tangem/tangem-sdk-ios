//
//  MillisecTimer.swift
//  TangemSdk
//
//  Created by Andrew Son on 24/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class MillisecTimer {
    private let logger: ((String) -> Void)?
    
    private var startTime: DispatchTime?
    
    public init(logger: ((String) -> Void)?) {
        self.logger = logger
    }
    
    public func start() {
        startTime = .now()
    }
    
    @discardableResult
    public func stop() -> Double {
        let millisec = Double(DispatchTime.now().uptimeNanoseconds - (startTime?.uptimeNanoseconds ?? DispatchTime.now().uptimeNanoseconds)) / 1_000_000
        logger?("Elapsed time in milliseconds: \(millisec)")
        return millisec
    }
}
