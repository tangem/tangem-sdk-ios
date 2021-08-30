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
    var style: TangemSdkStyle
    var isDisabled: Bool = false
    var isLoading: Bool = false
    
    var height: CGFloat = 50
    
    @ViewBuilder private var loadingOverlay: some View {
        if isLoading  {
            ZStack {
                style.colors.tint
                ActivityIndicatorView()
            }
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
        .colorMultiply(isDisabled ? style.colors.disabledButtonForeground : style.colors.buttonForeground)
        .background(isDisabled ? style.colors.disabledButtonBackground : style.colors.tint)
        .overlay(loadingOverlay)
        .cornerRadius(8)
        .allowsHitTesting(!isDisabled && !isLoading)
        .animation(.easeInOut(duration: 0.2))
    }
}
