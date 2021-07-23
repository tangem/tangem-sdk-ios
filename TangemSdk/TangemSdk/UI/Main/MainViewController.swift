//
//  MainViewController.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
class MainViewController: UIHostingController<MainView> {
    private(set) var state: InformationScreenViewController.State = .howToScan
    
    private var indicatorTotal: CGFloat = 0
    
    public func tickSD(remainingValue: Float, message: String, hint: String? = nil) {
        rootView.state = .delay(currentDelay: CGFloat(remainingValue), totalDelay: indicatorTotal)
//        indicatorView.tickSD(remainingValue: remainingValue)
//        hintLabel.text = hint
//        indicatorLabel.text = message
    }
    
    
    public func tickPercent(percentValue: Int, message: String, hint: String? = nil) {
        rootView.state = .progress(circleProgress: CGFloat(percentValue)/100.0)
//        indicatorView.tickPercent(percentValue: percentValue)
//        indicatorLabel.text = message
//        hintLabel.text = hint
//        indicatorView.currentPercentValue = percentValue
    }
    
    func setupIndicatorTotal(_ value: Float) {
        indicatorTotal = CGFloat(value)
    }
    
    func setState(_ state: InformationScreenViewController.State, animated: Bool) {
        switch state {
        case .howToScan:
            rootView.state = .scan
        case .idle:
            rootView.state = .default
        case .pausedSpinner:
            rootView.state = .default
        case .percentProgress:
            break
        case .securityDelay:
            break
        case .spinner:
            rootView.state = .default
        }
        
        self.state = state
    }
}
