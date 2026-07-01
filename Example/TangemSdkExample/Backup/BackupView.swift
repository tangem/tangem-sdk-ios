//
//  BackupView.swift
//  TangemSdkExample
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk

struct BackupView: View {
    @ObservedObject var viewModel: BackupViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                primaryCardSection
                separator
                backupCardsSection
                separator
                codesSection
                separator
                errorAndProceedSection
            }
            .padding([.horizontal, .bottom], 16)
        }
    }

    private var separator: some View {
        Color.gray.frame(width: 100, height: 1)
    }

    private var primaryCardSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.primaryCardTitle)

            actionButton("Read primary card", action: viewModel.readPrimaryCard)
        }
    }

    private var backupCardsSection: some View {
        VStack(spacing: 8) {
            Text("Maximum backup cards count is: \(viewModel.maxBackupCardsCount)")
            Text(viewModel.backupCardsCountTitle)

            actionButton("Add backup card", action: viewModel.addBackupCard)
        }
    }

    private var codesSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.accessCodeTitle)

            TextField("Access code for all cards", text: $viewModel.accessCode)
                .textFieldStyle(.roundedBorder)

            actionButton("Set access code", action: viewModel.setAccessCode)

            Text(viewModel.passcodeTitle)

            TextField("Passcode for all cards", text: $viewModel.passcode)
                .textFieldStyle(.roundedBorder)

            actionButton("Set passcode", action: viewModel.setPasscode)
        }
    }

    private var errorAndProceedSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.errorText)
                .foregroundStyle(.red)

            Button("Discard incompleted") {
                viewModel.discardIncompletedBackup()
            }

            Text(viewModel.stateTitle)

            actionButton("Proceed", action: viewModel.proceed)
        }
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(ExampleButton(isLoading: false))
            .frame(width: 200)
    }
}

#Preview {
    NavigationStack {
        BackupView(viewModel: BackupViewModel())
    }
}
