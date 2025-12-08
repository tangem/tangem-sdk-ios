//
//  Application.swift
//  TangemSDKExample
//
//  Created by Alexander Osokin on 10/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import UIKit
import TangemSdk
import SwiftUI

@main
struct Application: App {
    private let model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}

