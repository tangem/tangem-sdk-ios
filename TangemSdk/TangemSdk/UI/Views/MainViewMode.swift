//
//  MainViewMode.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 16.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
class MainViewModel: ObservableObject {
    @Published var viewState: MainView.ViewState = .scan
}
