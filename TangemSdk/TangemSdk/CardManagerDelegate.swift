//
//  CardManagerDelegate.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

public protocol CardManagerDelegate: class {
    func showAlertMessage(_ text: String)
    
    @available(iOS 13.0, *)
    func showSecurityDelay(remainingMilliseconds: Int)
    
    func requestPin(completion: @escaping () -> CompletionResult<String, Error>)
}

final class DefaultCardManagerDelegate: CardManagerDelegate {
    private let reader: NFCReaderText
    
    private lazy var delayFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = .second
        return formatter
    }()
    
    init(reader: NFCReaderText) {
        self.reader = reader
    }
    
    func showAlertMessage(_ text: String) {
        reader.alertMessage = text
    }
    
    func showSecurityDelay(remainingMilliseconds: Int) {
        if let timeString = delayFormatter.string(from: TimeInterval(remainingMilliseconds/100)) {
            let generator = UIImpactFeedbackGenerator(style: UIImpactFeedbackGenerator.FeedbackStyle.light)
            generator.impactOccurred()
            showAlertMessage(Localization.secondsLeft(timeString))
        }
    }
    
    func requestPin(completion: @escaping () -> CompletionResult<String, Error>) {
        //TODO:implement
    }
}
