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
    @State private var resultText: String = ""
    
    var body: some View {
        VStack {
            switch model.backupService.currentState {
            case .needBackupCardsCount:
                VStack(spacing: 20) {
                    Text("Backup cards count:")
                    
                    HStack {
                        Button("1") { count = 1 }
                            .buttonStyle(ExampleButton(isLoading: false))
                            .frame(width: 80, height: 30)
                        
                        Button("2") { count = 2 }
                            .buttonStyle(ExampleButton(isLoading: false))
                            .frame(width: 80, height: 30)
                    }
                }
            case .needAccessCode:
                TextField("Enter access code", text: $accessCode)
            case .needScanOriginCard:
                Text("Scan origin")
            case .needScanBackupCard(let index):
                Text("Scan backup with index: \(index)")
            case .needWriteOriginCard:
                Text("Scan origin again")
            case .needWriteBackupCard(let index):
                Text("Scan backup again with index: \(index)")
            case .finished:
                Text("You are great! Backup process succeded")
            }
            
            Text(resultText)
            
            Spacer()
            
            Button("Continue") {
                model.backupService.continueProcess(with: params) { result in
                    switch result {
                    case .success(let newState):
                        self.resultText = "New state is: \(newState)"
                    case .failure(let error):
                        self.resultText = "Error occured: \(error)"
                    }
                }
            }
        }
    }
    
    var params: StateParams {
        switch model.backupService.currentState {
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
