//
//  EnterUserCodeView.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct EnterUserCodeView: View {
    let title: String
    let cardId: String
    let placeholder: String
    let showForgotButton: Bool
    let completion: CompletionResult<String>
    
    @EnvironmentObject var style: TangemSdkStyle
    
    @State private var isLoading: Bool = false
    @State private var code: String = ""
    
    private var isContinueDisabled: Bool {
        code.trim().isEmpty
    }
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    UserCodeHeaderView(title: title, cardId: cardId, onCancel: onCancel)
                        .padding(.top, 8)

                    codeInput
                        .padding(.top, 16)

                    SecurityNoticeView()
                        .padding(.top, 8)

                    footer
                }
                .padding([.horizontal, .bottom])
                .onAppear(perform: onAppear)
                .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private var codeInput: some View {
        FloatingTextField(
            title: placeholder,
            text: $code,
            onCommit: onDone,
            shouldBecomeFirstResponder: true
        )
    }

    private var footer: some View {
        VStack(spacing: 16) {

            Spacer()

            if showForgotButton {
                SdkButton(
                    title: "reset_codes_btn_forgot_your_code".localized,
                    colors: style.colors.secondaryButtonColors,
                    action: onForgot
                )
            }

            SdkButton(
                title: "common_continue".localized,
                colors: style.colors.buttonColors,
                action: onDone
            )
        }
    }

    private func onAppear() {
        if isLoading {
            isLoading = false
        }
    }
    
    private func onCancel() {
        completion(.failure(.userCancelled))
    }
    
    private func onForgot() {
        completion(.failure(.userForgotTheCode))
    }
    
    private func onDone() {
        if isContinueDisabled {
            return
        }
        
        UIApplication.shared.endEditing()
        isLoading = true
        
        let userCode = code.trim()
        completion(.success(userCode))
    }
}

struct EnterUserCodeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EnterUserCodeView(title: "Title",
                              cardId: "0000 1111 2222 3333 444",
                              placeholder: "Enter code",
                              showForgotButton: true,
                              completion: {_ in})
            EnterUserCodeView(title: "Title",
                              cardId: "0000 1111 2222 3333 444",
                              placeholder: "Enter code",
                              showForgotButton: true,
                              completion: {_ in})
                .preferredColorScheme(.dark)
        }
        .environmentObject(TangemSdkStyle())
    }
}
