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
    let cardIdFormatted: String
    let placeholder: String
    let showForgotButton: Bool
    let accessCodeRepository: AccessCodeRepository?
    let completion: CompletionResult<String>
    
    @EnvironmentObject var style: TangemSdkStyle
    
    @State private var isLoading: Bool = false
    @State private var code: String = ""
    @State private var saveAccessCodeWithBiometry = false
    
    private var isContinueDisabled: Bool {
        code.trim().isEmpty
    }
    
    private var usingLocalAuthentication: Bool {
        guard let accessCodeRepository = accessCodeRepository else {
            return false
        }
        
        return accessCodeRepository.hasAccessToBiometricAuthentication()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            UserCodeHeaderView(title: title,
                               cardId: cardIdFormatted,
                               onCancel: onCancel)
                .padding(.top, 8)
            
            FloatingTextField(title: placeholder, text: $code, onCommit: onDone, isSecured: true)
                .padding(.top, 16)
            
            VStack(spacing: 16) {
                #warning("TODO: l10n")
                if usingLocalAuthentication {
                    Toggle("Save access code", isOn: $saveAccessCodeWithBiometry)
                    // TODO: Buggy toggle color
                    // Fix: https://github.com/tangem/tangem-app-ios/pull/156/files
                }
                
                Spacer()
                
                if showForgotButton {
                    Button("enter_user_code_button_title_forgot".localized, action: onForgot)
                        .buttonStyle(RoundedButton(colors: style.colors.secondaryButtonColors))
                }
                
                Button("common_continue".localized, action: onDone)
                    .buttonStyle(RoundedButton(colors: style.colors.buttonColors,
                                               isDisabled: isContinueDisabled,
                                               isLoading: isLoading))
            }
            .keyboardAdaptive(animated: .constant(true))
        }
        .padding([.horizontal, .bottom])
        .onAppear(perform: onAppear)
    }
    
    private func onAppear() {
        if isLoading {
            isLoading = false
        }
        
        let ignoreCard = accessCodeRepository?.ignoringCard(with: cardId) ?? false
        saveAccessCodeWithBiometry = !ignoreCard
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
        
        let accessCode = code.trim()
        
        guard
            saveAccessCodeWithBiometry,
            usingLocalAuthentication,
            let accessCodeRepository = accessCodeRepository
        else {
            accessCodeRepository?.setIgnoreCards(with: [cardId], ignore: true)
            completion(.success(accessCode))
            return
        }
        
        accessCodeRepository.saveAccessCode(accessCode, for: [cardId]) { result in
            self.isLoading = false
            
            switch result {
            case .success:
                completion(.success(accessCode))
            case .failure(let error):
                if error == .noBiometryAccess {
                    completion(.success(accessCode))
                }
            }
        }
    }
}

@available(iOS 13.0, *)
struct EnterUserCodeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EnterUserCodeView(title: "Title",
                              cardId: "0000111122223333444",
                              cardIdFormatted: "0000 1111 2222 3333 444",
                              placeholder: "Enter code",
                              showForgotButton: true,
                              accessCodeRepository: nil,
                              completion: {_ in})
            EnterUserCodeView(title: "Title",
                              cardId: "0000111122223333444",
                              cardIdFormatted: "0000 1111 2222 3333 444",
                              placeholder: "Enter code",
                              showForgotButton: true,
                              accessCodeRepository: nil,
                              completion: {_ in})
                .preferredColorScheme(.dark)
        }
        .environmentObject(TangemSdkStyle())
    }
}
