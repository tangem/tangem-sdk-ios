//
//  MainViewController.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
class MainViewController: UIHostingController<MainView> {
    var delayTimer: Timer?
    
    func setState(_ state: SessionViewState, animated: Bool) {
        rootView.state = state
    }
}
