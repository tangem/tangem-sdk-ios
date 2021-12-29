//
//  SettingsView.swift
//  TangemSdkExample
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    
    var body: some View {
        VStack {
            Toggle("Error handling", isOn: $model.handleErrors)
            Spacer()
        }
        .padding()
        .navigationBarTitle("Settings", displayMode: .inline)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
