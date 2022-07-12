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
    
    private let loggerSerialQueue = DispatchQueue(label: "com.tangem.tangemsdkexample.debugLogger.queue")
 
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss:SSS"
        return formatter
    }()
    
    func log(_ message: String, level: Log.Level) {
        guard Log.filter(level) else { return }
        
        loggerSerialQueue.async {
            let logString = "\(level.emoji) \(self.dateFormatter.string(from: Date())):\(level.prefix) \(message)"
            self.log(text: logString)
        }
    }
    
    func log(_ object: Any) {
        loggerSerialQueue.async {
            let text: String = (object as? JSONStringConvertible)?.json ?? "\(object)"
            self.log(text: text)
        }
    }
    
    func clear() {
        loggerSerialQueue.async {
            self.logsPublisher.send("")
        }
    }
    
    private func log(text: String) {
        if self.logsPublisher.value == DebugLogger.logPlaceholder {
            self.logsPublisher.send("")
        }
        
        let currentLogs = self.logsPublisher.value
        let newLogs = "\(text)\n\n" + currentLogs
        self.logsPublisher.send(newLogs)
    }
}
