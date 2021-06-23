//
//  TestHealethModel.swift
//  TangemSdkExample
//
//  Created by Alexander Osokin on 23.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class TestHealthModel: ObservableObject {
    // Outputs
    @Published var counter: Int = 0
    @Published var errorText: String = ""
    @Published var isScanning: Bool = false
    
    private var testTask: TestHealthTask? = nil
    
    private lazy var tangemSdk: TangemSdk = {
        var config = Config()
        config.logСonfig = .release
        //config.linkedTerminal = false
        config.allowedCardTypes = [.sdk]
        return TangemSdk(config: config)
    }()
    
    func start() {
        isScanning = true
        errorText = ""
        
        testTask = TestHealthTask()
        testTask!.onStep = {
            DispatchQueue.main.async {
                self.counter += 1
                print("Counter: \(self.counter)")
            }
        }
        
        tangemSdk.startSession(with: testTask!) { result in
            if case let .failure(error) = result {
                self.errorText = error.localizedDescription
            }
            
            self.isScanning = false
        }
    }
}
