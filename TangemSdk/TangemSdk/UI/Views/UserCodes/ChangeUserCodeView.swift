//
//  ChangeUserCodeView.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct ChangeUserCodeView: View {
    let type: UserCodeType
    let title: String
    let cardId: String
    let placeholder: String
    let confirmationPlaceholder: String
    var subtitle: String?
    let completion: CompletionResult<String>

    @State private var code: String = ""
    @State private var confirmation: String = ""
    @State private var error: String = ""
    @State private var isContinueDisabled: Bool = true
    @State private var validationTimer: Timer? = nil

    @EnvironmentObject var style: TangemSdkStyle

    var body: some View {
        Group {
            if let subtitle {
                newDesignBody(subtitle: subtitle)
            } else {
                legacyBody
            }
        }
        .padding([.horizontal, .bottom])
    }

    private var legacyBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            UserCodeHeaderView(
                title: title,
                cardId: cardId,
                onCancel: onCancel
            )
            .padding(.top, 8)

            fields

            VStack(spacing: 0) {
                Spacer()

                continueButton
            }
        }
    }

    private func newDesignBody(subtitle: String) -> some View {
        VStack(spacing: 0) {
            AccessCodeHeaderActions(onClose: onCancel)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold))
                        .padding(.top, 40)

                    Text(subtitle)
                        .font(.system(size: 16))
                        .foregroundColor(style.colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    fields
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)

            continueButton
        }
    }

    @ViewBuilder
    private var fields: some View {
        FloatingTextField(
            title: placeholder,
            text: $code.onUpdate(scheduleValidation),
            onCommit: onDone,
            shouldBecomeFirstResponder: true
        )
        .padding(.top, 16)

        FloatingTextField(
            title: confirmationPlaceholder,
            text: $confirmation.onUpdate(scheduleValidation),
            onCommit: onDone
        )
        .padding(.top, 8)

        Text(error)
            .font(.system(size: 13))
            .foregroundColor(style.colors.errorTint)
    }

    private var continueButton: some View {
        SdkButton(
            title: "common_continue".localized,
            colors: style.colors.buttonColors,
            isDisabled: isContinueDisabled,
            action: onDone
        )
    }

    private func onCancel() {
        completion(.failure(.userCancelled))
    }

    private func onDone() {
        if !isContinueDisabled {
            UIApplication.shared.endEditing()
            completion(.success(code.trim()))
        }
    }

    private func scheduleValidation() {
        validationTimer?.invalidate()
        validationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: validateInput)
    }

    private func validateInput(_ timer: Timer? = nil) {
        let trimmedCode = code.trim()
        let trimmedConfirmation = confirmation.trim()

        guard !trimmedCode.isEmpty, !trimmedConfirmation.isEmpty else {
            error = ""
            isContinueDisabled = true
            return
        }

        if code != confirmation {
            error = "pin_confirm_error_format".localized
            isContinueDisabled = true
            return
        }

        if trimmedCode.count < UserCodeType.minLength {
            error = type.shortLengthErrorMessage
            isContinueDisabled = true
            return
        }

        error = ""
        isContinueDisabled = false
        return
    }
}

// MARK: - Previews

#Preview {
    Group {
        ChangeUserCodeView(
            type: .accessCode,
            title: "Title",
            cardId: "0000 1111 2222 3333 444",
            placeholder: "Enter code",
            confirmationPlaceholder: "Confirm",
            completion: { _ in }
        )
        ChangeUserCodeView(
            type: .accessCode,
            title: "Title",
            cardId: "0000 1111 2222 3333 444",
            placeholder: "Enter code",
            confirmationPlaceholder: "Confirm",
            completion: { _ in }
        )
        .preferredColorScheme(.dark)
        ChangeUserCodeView(
            type: .accessCode,
            title: "New Access Code",
            cardId: "",
            placeholder: "Access Code",
            confirmationPlaceholder: "Confirm Access Code",
            subtitle: "Create a new password, then confirm it for this device •• 0000",
            completion: { _ in }
        )
    }
    .environmentObject(TangemSdkStyle())
}
