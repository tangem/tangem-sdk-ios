//
//  RoundedButtonStyle.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 13.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SdkButton: View {
    let title: String
    let colors: TangemSdkStyle.ButtonColors
    var isDisabled: Bool = false
    var isLoading: Bool = false
    let action: () -> Void

    private var foregroundColor: Color {
        isDisabled ? colors.disabledForegroundColor : colors.foregroundColor
    }

    private var backgroundColor: Color {
        isDisabled ? colors.disabledBackgroundColor : colors.backgroundColor
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(foregroundColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 46, maxHeight: 46)
                .background(backgroundColor)
                .overlay(loadingOverlay)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .allowsHitTesting(!isDisabled && !isLoading)
                .animation(.easeInOut(duration: 0.2), value: isDisabled)
        }
        .buttonStyle(BorderlessButtonStyle())
    }

    @ViewBuilder
    private var loadingOverlay: some View {
        if isLoading {
            ZStack {
                backgroundColor
                ActivityIndicatorView(color: foregroundColor)
            }
        } else {
            Color.clear
        }
    }
}
