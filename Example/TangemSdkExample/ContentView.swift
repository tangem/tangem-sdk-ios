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
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        Button("Clear logs", action: model.clear)
                        
                        VStack {
                            Text("Common")
                                .font(.title)
                            Button("Scan", action: model.scan)
                            Button("verifyCard", action: model.verifyCard)
                            Button("chainingExample", action: model.chainingExample)
                            Button("depersonalize", action: model.depersonalize)
                            Button("changePin1", action: model.changePin1)
                            Button("changePin2", action: model.changePin2)
                        }
                        
                        VStack {
                            Text("Sign")
                                .font(.title)
                            Button("Sign hash", action: model.signHash)
                            Button("Sign hashes", action: model.signHashes)
                        }
                        
                        VStack {
                            Text("Wallet")
                                .font(.title)
                            
                            VStack {
                                Button("Create wallet with config", action: model.createWallet)
                                
                                Toggle("Permanent wallet", isOn: $model.prohibitPurgeWallet)
                                
                                Picker("", selection: $model.curve) {
                                    ForEach(0..<EllipticCurve.allCases.count) { index in
                                        Text(EllipticCurve.allCases[index].rawValue)
                                            .tag(EllipticCurve.allCases[index])
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            .padding()
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.orange, lineWidth: 2))
                            
                            
                            Button("Purge wallet", action: model.purgeWallet)
                        }
                        
                        VStack {
                            Text("Operations with files")
                                .font(.title)
                            Button("readFiles", action: model.readFiles)
                            Button("readPublicFiles", action: model.readPublicFiles)
                            Button("writeSingleFile", action: model.writeSingleFile)
                            Button("writeSingleSignedFile", action: model.writeSingleSignedFile)
                            Button("writeMultipleFiles", action: model.writeMultipleFiles)
                            Button("deleteFirstFile", action: model.deleteFirstFile)
                            Button("deleteAllFiles", action: model.deleteAllFiles)
                            Button("updateFirstFileSettings", action: model.updateFirstFileSettings)
                        }
                        
                        VStack {
                            Text("Deprecated commands")
                                .font(.title)
                            Button("GetIssuerData", action: model.getIssuerData)
                            Button("writeIssuerData", action: model.writeIssuerData)
                            Button("readIssuerExtraData", action: model.readIssuerExtraData)
                            Button("writeIssuerExtraData", action: model.writeIssuerExtraData)
                            Button("readUserData", action: model.readUserData)
                            Button("writeUserData", action: model.writeUserData)
                            Button("writeUserProtectedData", action: model.writeUserProtectedData)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(width: geo.size.width)
                }
            }
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
