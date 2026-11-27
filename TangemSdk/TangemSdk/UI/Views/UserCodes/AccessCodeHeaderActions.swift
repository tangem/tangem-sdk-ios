//
//  AccessCodeHeaderActions.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct AccessCodeHeaderActions: View {
    let onClose: () -> Void

    @Environment(\.accessCodeFlow) private var accessCodeFlow
    @Environment(\.accessCodeScreen) private var accessCodeScreen

    private var supportScreen: TangemSdkScreen? {
        guard let accessCodeFlow, accessCodeFlow.isSupportAvailable else { return nil }

        return accessCodeScreen
    }

    var body: some View {
        HStack(spacing: 8) {
            if let supportScreen {
                supportButton(screen: supportScreen)
            }

            closeButton
        }
    }

    private func supportButton(screen: TangemSdkScreen) -> some View {
        Button {
            accessCodeFlow?.requestSupport(from: screen)
            onClose()
        } label: {
            Text("common_support".localized)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .contentShape(Capsule())
        }
        .glassButton()
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .glassButton()
        .accessibilityLabel("common_cancel".localized)
    }
}

private extension View {
    @ViewBuilder
    func glassButton() -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: Capsule())
        } else {
            buttonStyle(.plain)
                .background(Capsule().fill(.regularMaterial))
                .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
        }
    }
}

// MARK: - Previews

#Preview {
    AccessCodeHeaderActions(onClose: {})
        .padding()
        .background(Color.gray.opacity(0.1))
}
