//
//  RoundedButtonStyle.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 13.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct RoundedButton: ButtonStyle {
    var isDisabled: Bool = false
    var isLoading: Bool = false
    var bgColor: Color = .blue
    var bgDisabledColor: Color = .gray
    var height: CGFloat = 50
    
    @ViewBuilder private var loadingOverlay: some View {
        if isLoading  {
            ZStack {
                bgColor
                ActivityIndicatorView()
            }
        } else {
            Color.clear
        }
    }
    
    @ViewBuilder private var disabledOverlay: some View {
        if isDisabled  {
            Color.white.opacity(0.6)
        } else {
            Color.clear
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
            Spacer()
        }
        .frame(height: height)
        .padding(.horizontal, 10)
        .font(.system(size: 17, weight: .semibold, design: .default))
        .foregroundColor(Color.white)
        .background(isDisabled ? bgDisabledColor : bgColor)
        .overlay(loadingOverlay)
        .cornerRadius(8)
        .allowsHitTesting(!isDisabled && !isLoading)
    }
}
