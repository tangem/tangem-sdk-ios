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

    init(config: Config) {
        //self.model = MainViewModel()
        let view = MainView(style: config.style)
        super.init(rootView: view)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setState(_ state: SessionViewState) {
        switch (rootView.viewState, state) {
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
    
    private func map(state: SessionViewState) -> MainView.ViewState {
        switch state {
        case .default:
            return .default
        case .delay(let remaining, let total):
            return .delay(remaining: remaining - 1, total: total, label: remaining)
        case .progress(let percent):
            return .progress(percent: percent)
        case .scan:
            return .scan
        case .requestCode(let type, cardId: let cardId, completion: let completion):
            return .requestCode(type, cardId: cardId ?? "", completion: completion)
        case .requestCodeChange(let type, cardId: let cardId, completion: let completion):
            return .requestCodeChange(type, cardId: cardId ?? "", completion: completion)
        }
    }
    
    private func setState(_ state: MainView.ViewState) {
        rootView.viewState = state
    }
}
