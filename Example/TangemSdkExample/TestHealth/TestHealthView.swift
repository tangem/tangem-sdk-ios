//
//  TestHealthView.swift
//  TangemSdkExample
//
//  Created by Alexander Osokin on 23.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct TestHealthView: View {
    @EnvironmentObject var model: TestHealthModel
    
    var body: some View {
        VStack {
            Text("Counter: \(model.counter)")
                .padding(.top, 60)
                .font(.title)
            
            if !model.errorText.isEmpty {
                Text("Error: \(model.errorText)")
            }
            
            Spacer()
            
            Button("Start", action: model.start)
                .buttonStyle(ExampleButton(isLoading: model.isScanning))
                .frame(width: 100)
                .padding()
        }
    }
}

struct TestHealthView_Previews: PreviewProvider {
    static var previews: some View {
        TestHealthView().environmentObject(TestHealthModel())
    }
}
