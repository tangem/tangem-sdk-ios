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
    @AppStorage("handleErrors") private var handleErrors: Bool = true
    @AppStorage("displayLogs") private var displayLogs: Bool = false
    @AppStorage("useDevApi") private var useDevApi: Bool = false
    @AppStorage("isDevelopmentMode") private var isDevelopmentMode: Bool = false
    @AppStorage("accessCodeRequestPolicy") private var accessCodeRequestPolicy: AccessCodeRequestPolicy = .default

    var body: some View {
        VStack {
            Toggle("Error handling", isOn: $handleErrors)

            Toggle("Display logs", isOn: $displayLogs)

            Toggle("Dev api", isOn: $useDevApi)

            Toggle("Dev mode", isOn: $isDevelopmentMode)

            Text("Access code request policy")
                .fontWeight(.bold)
                .padding()

            Picker("", selection: $accessCodeRequestPolicy) {
                ForEach(0 ..< AccessCodeRequestPolicy.allCases.count, id: \.self) { index in
                    Text(AccessCodeRequestPolicy.allCases[index].rawValue)
                        .tag(AccessCodeRequestPolicy.allCases[index])
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Button("Remove access codes and tokens") {
                AccessCodeRepository().clear()
                CardAccessTokensRepository().clear()
            }
            .padding()

            Spacer()
        }
        .padding()
        .navigationBarTitle("Settings", displayMode: .inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
