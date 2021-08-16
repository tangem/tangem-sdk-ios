//
//  MainViewMode.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
class MainViewModel: ObservableObject {
    @Published var viewState: MainView.ViewState = .scan
}
