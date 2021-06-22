//
//  ContentView.swift
//  TangemSDKExample
//
//  Created by Alexander Osokin on 04.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk

struct ContentView: View {
    @EnvironmentObject var model: AppModel
    
    var body: some View {
        GeometryReader { geo in
            VStack {

                ScrollView {
                    Text(model.logText)
                        .padding(.horizontal, 16)
                        .font(.body)
                }
                .clipped()
                .frame(width: geo.size.width, height: 400)
                .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange, lineWidth: 2)
                            .padding(.horizontal, 8))
                .contextMenu {
                    Button("Copy") {
                        UIPasteboard.general.string = model.logText
                    }
                }
                
                ScrollView {
                    VStack {
                        Button("Clear logs", action: model.clear)
                        
                        Picker("Select method", selection: $model.method) {
                            ForEach(0..<AppModel.Method.allCases.count) { index in
                                Text(AppModel.Method.allCases[index].rawValue)
                                    .tag(AppModel.Method.allCases[index])
                            }
                        }
                        
                        Button("Start", action: model.start)
                            .buttonStyle(ExampleButton(isLoading: model.isScanning))
                            .frame(width: 100)
                            .padding()
                        
                        additionalView
                    }
                    .padding(.horizontal, 20)
                    .frame(width: geo.size.width)
                }
            }
        }
    }
    
    @ViewBuilder
    var additionalView: some View {
        switch model.method {
        case .attest:
            VStack {
                Text("Attestation configuration")
                    .font(.headline)
                    .bold()
                
                Picker("", selection: $model.attestationMode) {
                    ForEach(0..<AttestationTask.Mode.allCases.count) { index in
                        Text(AttestationTask.Mode.allCases[index].rawValue)
                            .tag(AttestationTask.Mode.allCases[index])
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding()
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 2))
        case .createWallet:
            VStack {
                Text("Create wallet configuration")
                    .font(.headline)
                    .bold()
                
                Toggle("Is permanent wallet", isOn: $model.isPermanent)
                    .disabled(!model.canSelectWalletSettings)
                
                Picker("", selection: $model.curve) {
                    ForEach(0..<model.supportedCurves.count) { index in
                        Text(model.supportedCurves[index].rawValue)
                            .tag(model.supportedCurves[index])
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding()
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 2))
        default:
            EmptyView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var model = AppModel()
    
    static var previews: some View {
        ContentView()
            .environmentObject(model)
    }
}
