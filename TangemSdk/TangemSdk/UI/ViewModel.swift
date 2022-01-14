//
//  ViewModel.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
class ViewModel<ViewState>: ObservableObject {
    @Published var viewState: ViewState
    
    init(viewState: ViewState) {
        self.viewState = viewState
    }
}
