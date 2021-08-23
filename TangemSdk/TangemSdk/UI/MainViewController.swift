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

    init(config: Config) {
        let view = MainView(style: config.style)
        super.init(rootView: view)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setState(_ state: SessionViewState) {
        rootView.viewState = state
    }
}
