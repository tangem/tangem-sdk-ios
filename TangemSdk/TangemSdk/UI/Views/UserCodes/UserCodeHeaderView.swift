//
//  UserCodeHeaderView.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct UserCodeHeaderView: View {
    let title: String
    let cardId: String
    let onCancel: () -> Void

    @EnvironmentObject var style: TangemSdkStyle
    @Environment(\.accessCodeFlow) private var accessCodeFlow
    @Environment(\.accessCodeScreen) private var accessCodeScreen

    private var supportScreen: TangemSdkScreen? {
        guard let accessCodeFlow, accessCodeFlow.isSupportAvailable else { return nil }

        return accessCodeScreen
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()

                if accessCodeFlow?.usesNewDesign == true {
                    HStack(spacing: 8) {
                        if let supportScreen {
                            supportButton(screen: supportScreen)
                        }

                        closeButton
                    }
                } else {
                    Button("common_cancel".localized, action: onCancel)
                        .foregroundColor(style.colors.tint)
                }
            }.padding(.bottom, 16)

            Text(title)
                .font(Font.system(size: 24).bold())
                .lineLimit(1)

            Text(cardId)
                .font(.system(size: 17))
        }
    }

    private func supportButton(screen: TangemSdkScreen) -> some View {
        Button {
            accessCodeFlow?.requestSupport(from: screen)
            onCancel()
        } label: {
            Text("common_support".localized)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(style.colors.secondaryButtonColors.foregroundColor)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Capsule().fill(style.colors.secondaryButtonColors.backgroundColor))
        }
    }

    private var closeButton: some View {
        Button(action: onCancel) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(style.colors.secondaryButtonColors.foregroundColor)
                .frame(width: 32, height: 32)
                .background(Circle().fill(style.colors.secondaryButtonColors.backgroundColor))
        }
        .accessibilityLabel("common_cancel".localized)
    }
}

// MARK: - Previews

#Preview {
    Group {
        UserCodeHeaderView(title: "Enter access code", cardId: "0000 0000 0000 0000", onCancel: {})
        UserCodeHeaderView(title: "Enter access code", cardId: "0000 0000 0000 0000", onCancel: {})
            .preferredColorScheme(.dark)
    }
    .environmentObject(TangemSdkStyle())
}
