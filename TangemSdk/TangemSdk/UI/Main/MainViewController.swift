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
    var trues: Bool = true
    func setState(_ state: SessionViewState, animated: Bool) {
        if case let .delay(remaining, total) = state {
            if trues {
                rootView.state = state
                trues = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.rootView.state = .delay(remaining: remaining - 1, total: total)
                }
              
            } else {
            
            rootView.state = .delay(remaining: remaining - 1, total: total)
            }
        } else {
            rootView.state = state
        }
    }
}
