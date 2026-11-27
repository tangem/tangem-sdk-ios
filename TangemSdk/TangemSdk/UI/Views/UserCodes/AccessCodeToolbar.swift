//
//  AccessCodeToolbar.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct AccessCodeToolbar: View {
    let onCancel: () -> Void

    @EnvironmentObject var style: TangemSdkStyle
    @Environment(\.accessCodeFlow) private var accessCodeFlow
    @Environment(\.accessCodeScreen) private var accessCodeScreen

    private var supportScreen: TangemSdkScreen? {
        guard let accessCodeFlow, accessCodeFlow.isSupportAvailable else { return nil }

        return accessCodeScreen
    }

    var body: some View {
        HStack(spacing: 8) {
            Spacer()

            if let supportScreen {
                supportButton(screen: supportScreen)
            }

            closeButton
        }
        .frame(height: 44)
    }

    private func supportButton(screen: TangemSdkScreen) -> some View {
        Button {
            accessCodeFlow?.requestSupport(from: screen)
            onCancel()
        } label: {
            Text("common_support".localized)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(style.colors.secondaryButtonColors.foregroundColor)
                .padding(.horizontal, 14)
                .frame(minWidth: 56, minHeight: 36)
                .accessCodeToolbarMaterial(Capsule(), style: style)
        }
        .buttonStyle(.plain)
    }

    private var closeButton: some View {
        Button(action: onCancel) {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(style.colors.secondaryButtonColors.foregroundColor)
                .frame(width: 44, height: 44)
                .accessCodeToolbarMaterial(Circle(), style: style)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("common_cancel".localized)
    }
}

private extension View {
    @ViewBuilder
    func accessCodeToolbarMaterial(_ shape: some Shape, style: TangemSdkStyle) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.interactive(), in: shape)
        } else {
            background(shape.fill(style.colors.secondaryButtonColors.backgroundColor))
        }
    }
}

// MARK: - Previews

#Preview {
    AccessCodeToolbar(onCancel: {})
        .padding()
        .environmentObject(TangemSdkStyle())
}
