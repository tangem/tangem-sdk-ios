//
//  DebugLogger.swift
//  TangemSdkExample
//
//  Created by Alexander Osokin on 08.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine

class DebugLogger: TangemSdkLogger {
    var logsPublisher: CurrentValueSubject<String, Never> = .init("")
    
    static let logPlaceholder = "Logs will appear here"

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss:SSS"
        return formatter
    }()
    
    func log(_ message: String, level: Log.Level) {
        guard Log.filter(level) else { return }
        
        let logString = "\(level.emoji) \(self.dateFormatter.string(from: Date())):\(level.prefix) \(message)"
        log(text: logString)
    }
    
    func log(_ object: Any) {
        let text: String = (object as? JSONStringConvertible)?.json ?? "\(object)"
        log(text: text)
    }
    
    func clear() {
        logsPublisher.send("")
    }
    
    private func log(text: String) {
        if logsPublisher.value == DebugLogger.logPlaceholder {
            logsPublisher.send("")
        }
        
        let currentLogs = logsPublisher.value
        let newLogs = "\(text)\n\n" + currentLogs
        logsPublisher.send(newLogs)
    }
}
