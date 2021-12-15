//
//  EnterUserCodeView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 12.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct EnterUserCodeView: View {
    let title: String
    let cardId: String
    let placeholder: String
    let completion: CompletionResult<String>
    
    @EnvironmentObject var style: TangemSdkStyle
    
    @State private var isLoading: Bool = false
    @State private var code: String = ""
    
    private var isContinueDisabled: Bool {
        code.trim().isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            UserCodeHeaderView(title: title,
                               cardId: cardId,
                               onCancel: onCancel)
                .padding(.top, 8)
            
            FloatingTextField(title: placeholder, text: $code, onCommit: onDone, isSecured: true)
                .padding(.top, 16)
            
            VStack(spacing: 0) {
                
                Spacer()
                
                Button("common_continue".localized, action: onDone)
                    .buttonStyle(RoundedButton(style: style,
                                               isDisabled: isContinueDisabled,
                                               isLoading: isLoading))
            }
            .keyboardAdaptive(animated: .constant(true))
        }
        .padding([.horizontal, .bottom])
        .onAppear {
            if isLoading {
                isLoading = false
            }
        }
    }
    
    private func onCancel() {
        completion(.failure(.userCancelled))
    }
    
    private func onDone() {
        if !isContinueDisabled {
            UIApplication.shared.endEditing()
            isLoading = true
            completion(.success(code.trim()))
        }
    }
}

@available(iOS 13.0, *)
struct EnterUserCodeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EnterUserCodeView(title: "Title",
                              cardId: "0000 1111 2222 3333 444",
                              placeholder: "Enter code",
                              completion: {_ in})
            EnterUserCodeView(title: "Title",
                              cardId: "0000 1111 2222 3333 444",
                              placeholder: "Enter code",
                              completion: {_ in})
                .preferredColorScheme(.dark)
        }
        .environmentObject(TangemSdkStyle())
    }
}
