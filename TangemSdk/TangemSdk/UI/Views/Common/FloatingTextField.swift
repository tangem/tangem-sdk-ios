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
    var isSecured: Bool = false
    
    @EnvironmentObject var style: TangemSdkStyle
    
    var body: some View {
        VStack(spacing: 6) {
            
            ZStack(alignment: .leading) {
                
                Text(title)
                    .foregroundColor(text.wrappedValue.isEmpty ? Color(.placeholderText) : style.colors.tint)
                    .offset(y: text.wrappedValue.isEmpty ? 0 : -32)
                    .scaleEffect(text.wrappedValue.isEmpty ? 1 : 0.76, anchor: .leading)
                
                textField
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .font(.system(size: 17))
            }
            
            Color(UIColor.opaqueSeparator)
                .frame(height: 1)
        }
        .padding(.top, 20)
        .animation(Animation.easeInOut(duration: 0.1))
    }
    
    @ViewBuilder
    private var textField: some View {
        if isSecured {
            SecureField("", text: text, onCommit: onCommit)
        } else {
            TextField("", text: text, onCommit: onCommit)
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


