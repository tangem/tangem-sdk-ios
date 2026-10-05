//
//  ResetPinView.swift
//  TangemSdkExample
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk

struct ResetPinView: View {
    @ObservedObject var viewModel: ResetPinViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TextField("Access code", text: $viewModel.accessCode)
                    .textFieldStyle(.roundedBorder)

                actionButton("Set access code", action: viewModel.setAccessCode)

                TextField("Passcode", text: $viewModel.passcode)
                    .textFieldStyle(.roundedBorder)

                actionButton("Set passcode", action: viewModel.setPasscode)

                Text(viewModel.errorText)
                    .foregroundStyle(.red)

                if let serviceErrorText = viewModel.serviceErrorText {
                    Text(serviceErrorText)
                        .foregroundStyle(.red)
                }

                Text(viewModel.stateTitle)
                    .font(.title)
            }
            .padding(.horizontal, 16)
        }
        .safeAreaInset(edge: .bottom) {
            actionButton("Proceed", action: viewModel.proceed)
                .padding(.bottom, 16)
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
        ResetPinView(viewModel: ResetPinViewModel())
    }
}
