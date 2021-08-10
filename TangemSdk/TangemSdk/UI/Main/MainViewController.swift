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
    func setState(_ state: SessionViewState, animated: Bool) {
        switch (rootView.state, state) {
        case (.delay, .delay):
            setState(map(state: state))
        case (_, .delay(let remaining, let total)):
            setState(.delay(remaining: remaining, total: total, label: remaining))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.setState(self.map(state: state))
            }
        default:
            setState(map(state: state))
        }
    }
    
    private func map(state: SessionViewState) -> MainView.State {
        switch state {
        case .default:
            return .default
        case .delay(let remaining, let total):
            return .delay(remaining: remaining - 1, total: total, label: remaining)
        case .progress(let percent):
            return .progress(percent: percent)
        case .scan:
            return .scan
        }
    }
    
    private func setState(_ state: MainView.State) {
        withAnimation {
            rootView.state = state
        }
    }
}
