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
    @EnvironmentObject var backupService: BackupService
    
    @State private var count: Int = 2
    @State private var accessCode: String = ""
    @State private var passcode: String = ""
    @State private var errorText: String = ""
    
    @ViewBuilder
    var separatorView: some View {
        Spacer()
        Color.gray.frame(width: 100, height: 1).clipped()
        Spacer()
    }
    
    var stateTitle: String {
        switch backupService.currentState {
        case .preparing:
            return "Preparing"
        case .needWriteOriginCard:
            return "Scan origin card again"
        case .needWriteBackupCard(let index):
            return "Scan backup card again with index: \(index)"
        case .finished:
            return "Backup succeded"
        }
    }
    
    var body: some View {
        VStack {
            
            Spacer()
            
            VStack(spacing: 8) {
                let msg = "Has origin card: \(backupService.originCardIsSet)"
                Text(msg)
                
                Button("Read origin card") {
                    backupService.readOriginCard { result in
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
            }
            
            separatorView
            
            VStack(spacing: 8) {
                Text("Maximum backup cards count is: \(BackupService.maxBackupCardsCount)")
                
                Text("Added backup cards count is: \(backupService.addedBackupCardsCount)")
                
                Button("Add backup card") {
                    backupService.addBackupCard { result in
                        switch result {
                        case .success(let newState):
                            self.errorText = ""
                            print("New state is: \(newState)")
                        case .failure(let error):
                            self.errorText = "Error occured: \(error)"
                        }
                    }
                }
                .buttonStyle(ExampleButton(/*isDisabled: !backupService.canAddBackupCards,*/
                                           isLoading: false))
                .frame(width: 200)
            }
            
            separatorView
            
            VStack(spacing: 8) {
                let msg1 = "Has access code: \(backupService.accessCodeIsSet)"
                Text(msg1)

                
                TextField("Access code for all cards", text: $accessCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Set access code") {
                    do {
                        try backupService.setAccessCode(accessCode)
                        self.errorText = ""
                        UIApplication.shared.endEditing()
                    } catch {
                        self.errorText = "Error occured: \(error)"
                    }
                }
                .buttonStyle(ExampleButton(isLoading: false))
                .frame(width: 200)
                
                let msg2 = "Has passcode: \(backupService.passcodeIsSet)"
                Text(msg2)

                
                TextField("Passcode for all cards", text: $passcode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Set passcode") {
                    do {
                        try backupService.setPasscode(passcode)
                        self.errorText = ""
                        UIApplication.shared.endEditing()
                    } catch {
                        self.errorText = "Error occured: \(error)"
                    }
                }
                .buttonStyle(ExampleButton(isLoading: false))
                .frame(width: 200)
            }
            
            separatorView
            
            Text(errorText)
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Button("Discard saved") {
                    backupService.discardSavedBackup()
                }
                
                Text("Current state is: \(stateTitle)")
                
                Button("Proceed") {
                    backupService.proceedBackup() { result in
                        switch result {
                        case .success(let newState):
                            self.errorText = ""
                            print("New state is: \(newState)")
                        case .failure(let error):
                            self.errorText = "Error occured: \(error)"
                        }
                    }
                }
                .buttonStyle(ExampleButton(/*isDisabled: !backupService.canProceed,*/
                                           isLoading: false))
                .frame(width: 200)
            }
        }
        .navigationBarTitle("Backup", displayMode: .inline)
        .padding([.horizontal, .bottom], 16)
    }
}

struct BackupView_Previews: PreviewProvider {
    static let sdk = TangemSdk()
    
    static var previews: some View {
        BackupView()
            .environmentObject(BackupService(sdk: sdk))
    }
}
