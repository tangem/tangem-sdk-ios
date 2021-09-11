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
                    HStack {
                    Text(model.logText)
                        .font(.caption)

                        Spacer()
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 14)
                .clipped()
                .frame(width: geo.size.width)
                .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange, lineWidth: 2)
                            .padding(.horizontal, 8))
                
                VStack(spacing: 4) {
                    HStack {
                        Button("Clear", action: model.clear)
                        Button("Copy", action: model.copy)
                    }
                    
                    additionalView
                        .padding(.top, 4)
                    
                    Picker("", selection: $model.method) {
                        ForEach(0..<AppModel.Method.allCases.count) { index in
                            Text(AppModel.Method.allCases[index].rawValue)
                                .tag(AppModel.Method.allCases[index])
                        }
                    }.labelsHidden()
                    
                    Button("Start") { model.start() }
                        .buttonStyle(ExampleButton(isLoading: model.isScanning))
                        .frame(width: 100)
                        .padding()

                }
                .padding(.horizontal, 8)
                .frame(width: geo.size.width)
            }
        }
        .padding(.bottom, 8)
        .actionSheet(isPresented: $model.showWalletSelection) {
            let walletButtons: [Alert.Button] = model.card?.wallets.map { wallet in
                let publicKey = wallet.publicKey.hexString
                let formattedKey = "\(publicKey.prefix(6))...\(publicKey.suffix(6)) (\(wallet.curve.rawValue))"
                
                return ActionSheet.Button.default(Text(formattedKey)) {
                    model.start(walletPublicKey: wallet.publicKey)
                }
            } ?? []
            
            let cancelButton = ActionSheet.Button.cancel {
                model.isScanning = false
            }
            
            return ActionSheet(title: Text("Select wallet"),
                               message: nil,
                               buttons: walletButtons + [cancelButton])
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
                
                if let supportedCurves = model.card?.supportedCurves {
                    Picker("", selection: $model.curve) {
                        ForEach(0..<supportedCurves.count) { index in
                            Text(supportedCurves[index].rawValue)
                                .tag(supportedCurves[index])
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .padding()
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 2))
        case .signHash, .signHashes, .derivePublicKey:
            VStack {
                Text("Hd path")
                    .font(.headline)
                    .bold()
                
                TextField("\"m/0/1\"", text: $model.hdPath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding()
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 2))
        case .jsonrpc:
            VStack {
                Text("Json request")
                    .font(.headline)
                    .bold()
                
                if #available(iOS 14.0, *) {
                    TextEditor(text: $model.json)
                        .frame(height: 100)
                    
                    Button("Paste json", action: model.pasteJson)
                } else {
                    HStack {
                        Spacer()
                        Button("Print json", action: model.printJson)
                        Spacer()
                        Button("Paste json", action: model.pasteJson)
                        Spacer()
                    }
                }
            }
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .padding()
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 2))
            .onAppear(perform: {
                if model.json.isEmpty {
                    model.json = model.jsonRpcTemplate
                }
            })
            
        default:
            EmptyView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var model = AppModel()
    
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 8")
            .environmentObject(model)
    }
}
