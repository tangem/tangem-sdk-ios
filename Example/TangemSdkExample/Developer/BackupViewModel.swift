//
//  BackupViewModel.swift
//  TangemSdkExample
//
//  Created by Alexander Osokin on 27.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import UIKit

@MainActor
final class BackupViewModel: ObservableObject {
    @Published var accessCode: String = ""
    @Published var passcode: String = ""
    @Published var errorText: String = ""

    @Published private(set) var primaryCardTitle: String = ""
    @Published private(set) var backupCardsCountTitle: String = ""
    @Published private(set) var accessCodeTitle: String = ""
    @Published private(set) var passcodeTitle: String = ""
    @Published private(set) var stateTitle: String = ""

    var isSetUp: Bool { backupService != nil }

    private var backupService: BackupService?

    init() {}

    func setup(backupService: BackupService) {
        guard !isSetUp else { return }
        self.backupService = backupService
        syncState()
    }

    func readPrimaryCard() {
        backupService?.readPrimaryCard { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success:
                    self.errorText = ""
                case .failure(let error):
                    self.errorText = "Error occurred: \(error)"
                }
                self.syncState()
            }
        }
    }

    func addBackupCard() {
        backupService?.addBackupCard { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success:
                    self.errorText = ""
                case .failure(let error):
                    self.errorText = "Error occurred: \(error)"
                }
                self.syncState()
            }
        }
    }

    func setAccessCode() {
        do {
            try backupService?.setAccessCode(accessCode)
            errorText = ""
            UIApplication.shared.endEditing()
        } catch {
            errorText = "Error occurred: \(error)"
        }
        syncState()
    }

    func setPasscode() {
        do {
            try backupService?.setPasscode(passcode)
            errorText = ""
            UIApplication.shared.endEditing()
        } catch {
            errorText = "Error occurred: \(error)"
        }
        syncState()
    }

    func discardIncompletedBackup() {
        backupService?.discardIncompletedBackup()
        syncState()
    }

    func proceed() {
        backupService?.proceedBackup { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success:
                    self.errorText = ""
                case .failure(let error):
                    self.errorText = "Error occurred: \(error)"
                }
                self.syncState()
            }
        }
    }

    private func syncState() {
        guard let backupService else { return }

        primaryCardTitle = "Has primary card: \(backupService.primaryCardIsSet)"
        backupCardsCountTitle = "Added backup cards count is: \(backupService.addedBackupCardsCount)"
        accessCodeTitle = "Has access code: \(backupService.accessCodeIsSet)"
        passcodeTitle = "Has passcode: \(backupService.passcodeIsSet)"

        switch backupService.currentState {
        case .preparing:
            stateTitle = "Current state is: Preparing"
        case .finalizingPrimaryCard:
            stateTitle = "Current state is: Scan primary card again"
        case .finalizingBackupCard(let index):
            stateTitle = "Current state is: Scan backup card again with index: \(index)"
        case .finished:
            stateTitle = "Current state is: Backup succeeded"
        }
    }
}
