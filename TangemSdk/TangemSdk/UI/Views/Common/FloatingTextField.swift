//
//  FloatingTextField.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 19.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct FloatingTextField: View {
    let title: String
    let text: Binding<String>
    var onCommit: () -> Void = {}
    /// iOS15+
    var shouldBecomeFirstResponder: Bool = false
    
    @EnvironmentObject private var style: TangemSdkStyle
    @State private var isSecured: Bool = true
    
    @ViewBuilder
    private var textField: some View {
        if #available(iOS 15.0, *) {
            FocusableTextField(isSecured: isSecured,
                               shouldBecomeFirstResponder: shouldBecomeFirstResponder,
                               text: text,
                               onCommit: onCommit)
        } else {
            legacyTextField
        }
    }
    
    @ViewBuilder
    private var legacyTextField: some View {
        if isSecured {
            SecureField("", text: text, onCommit: onCommit)
        } else {
            TextField("", text: text, onCommit: onCommit)
        }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            
            HStack {
                ZStack(alignment: .leading) {
                    
                    Text(title)
                        .foregroundColor(text.wrappedValue.isEmpty ? Color(.placeholderText) : style.colors.tint)
                        .offset(y: text.wrappedValue.isEmpty ? 0 : -32)
                        .scaleEffect(text.wrappedValue.isEmpty ? 1 : 0.76, anchor: .leading)
                    
                    textField
                        .keyboardType(.alphabet)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(size: 17))
                        .frame(height: 17)
                }
                
                Button(action: toggleSecured) {
                    Image(systemName: isSecured ? "eye" : "eye.slash")
                        .foregroundColor(.gray)
                }
            }
            
            Color(UIColor.opaqueSeparator)
                .frame(height: 1)
        }
        .padding(.top, 20)
        .animation(Animation.easeInOut(duration: 0.1))
    }
    
    private func toggleSecured() {
        isSecured.toggle()
    }
}

@available(iOS 15.0, *)
private extension FloatingTextField {
    enum Field: Hashable {
        case secure
        case plain
    }
    
    struct FocusableTextField: View {
        let isSecured: Bool
        let shouldBecomeFirstResponder: Bool
        let text: Binding<String>
        var onCommit: () -> Void = {}
        
        @FocusState private var focusedField: Field?
        
        var body: some View {
            ZStack {
                if isSecured {
                    SecureField("", text: text, onCommit: onCommit)
                        .focused($focusedField, equals: .secure)
                } else {
                    TextField("", text: text, onCommit: onCommit)
                        .focused($focusedField, equals: .plain)
                }
            }
            .onAppear(perform: onAppear)
            .onChange(of: isSecured) { newValue in
                setFocus(for: newValue)
            }
        }
        
        private func setFocus(for value: Bool) {
            focusedField = value ? .secure : .plain
        }
        
        private func onAppear() {
            if shouldBecomeFirstResponder {
                // Works only with huge delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    setFocus(for: isSecured)
                }
            }
        }
    }
}


@available(iOS 13.0, *)
struct FloatingTextField_Previews: PreviewProvider {
    @State static var text: String = "002139123"
    
    static var previews: some View {
        FloatingTextField(title: "Access code", text: $text)
            .environmentObject(TangemSdkStyle())
    }
}
