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
    let completion: ((String?) -> Void)
    
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
            SecureField(placeholder, text: $code, onCommit: onDone)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .font(.system(size: 17))
                .padding(.top, 36)
            
            Color(UIColor.opaqueSeparator)
                .frame(height: 1)
            
            Spacer()
            
            Button("common_continue".localized, action: onDone)
                .buttonStyle(RoundedButton(isDisabled: isContinueDisabled,
                                           isLoading: isLoading,
                                           bgColor: style.colors.tint))
        }
        .padding([.horizontal, .bottom])
        .onAppear {
            if isLoading {
                isLoading = false
            }
        }
    }
    
    private func onCancel() {
        completion(nil)
    }
    
    private func onDone() {
        if !isContinueDisabled {
            isLoading = true
            completion(code.trim())
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
