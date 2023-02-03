//
//  SettingsView.swift
//  TangemSdkExample
//
//  Created by Alexander Osokin on 21.10.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    
    var body: some View {
        VStack {
            Toggle("Error handling", isOn: $model.handleErrors)
            
            Toggle("Display logs", isOn: $model.displayLogs)
            
            Text("Access code request policy")
                .fontWeight(.bold)
                .padding()
            
            Picker("", selection: $model.accessCodeRequestPolicy) {
                ForEach(0..<AccessCodeRequestPolicy.allCases.count, id: \.self) { index in
                    Text(AccessCodeRequestPolicy.allCases[index].rawValue)
                        .tag(AccessCodeRequestPolicy.allCases[index])
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Button("Remove access codes", action: model.onRemoveAccessCodes)
                .padding()
            
            Spacer()
        }
        .padding()
        .navigationBarTitle("Settings", displayMode: .inline)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppModel())
    }
}
