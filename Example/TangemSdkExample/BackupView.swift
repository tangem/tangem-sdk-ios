//
//  BackupView.swift
//  TangemSdkExample
//
//  Created by Alexander Osokin on 27.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk

struct BackupView: View {
    @EnvironmentObject var model: AppModel
    
    @State private var count: Int = 2
    @State private var accessCode: String = ""
    @State private var errorText: String = ""
    @State private var currentState: BackupServiceState = .needBackupCardsCount
    
    var body: some View {
        VStack {
            
            Spacer()
            
            switch currentState {
            case .needBackupCardsCount:
                VStack(spacing: 20) {
                    Text("Select backup cards count:")
                    
                    Text("Current value is \(count)")
                    
                    HStack {
                        Button("1") { count = 1 }
                            .buttonStyle(ExampleButton(isLoading: false))
                            .frame(width: 80, height: 30)
                        
                        Button("2") { count = 2 }
                            .buttonStyle(ExampleButton(isLoading: false))
                            .frame(width: 80, height: 30)
                    }
                    .padding(.top, 10)
                }
            case .needAccessCode:
                VStack(spacing: 20) {
                    Text("Access code for all cards:")
                    TextField("Enter code", text: $accessCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            case .needScanOriginCard:
                Text("Scan origin card")
            case .needScanBackupCard(let index):
                Text("Scan backup card with index: \(index)")
            case .needWriteOriginCard:
                Text("Scan origin card again")
            case .needWriteBackupCard(let index):
                Text("Scan backup card again with index: \(index)")
            case .finished:
                Text("You are great! Backup process succeded")
            }
            
            Spacer()
            
            Text(errorText)
            
            Button("Continue") {
                model.backupService.continueProcess(with: params) { result in
                    switch result {
                    case .success(let newState):
                        self.errorText = ""
                        print("New state is: \(newState)")
                    case .failure(let error):
                        self.errorText = "Error occured: \(error)"
                    }
                }
            }
            .buttonStyle(ExampleButton(isLoading: false))
            .frame(width: 200)
            .padding(.top, 16)
        }
        .padding([.horizontal, .bottom], 16)
        .onReceive(model.backupService.$currentState, perform: { state in
            currentState = state
        })
    }
    
    private var params: StateParams {
        switch model.backupService.currentState  {
        case .needBackupCardsCount:
            return .backupCardsCount(count)
        case .needAccessCode:
            return .accessCode(accessCode)
        default:
            return .empty
        }
    }
}

struct BackupView_Previews: PreviewProvider {
    static var model = AppModel()
    
    static var previews: some View {
        BackupView()
            .environmentObject(model)
    }
}
