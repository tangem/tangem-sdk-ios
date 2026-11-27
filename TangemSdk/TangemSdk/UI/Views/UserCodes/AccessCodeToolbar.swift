//
//  AccessCodeToolbar.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    func accessCodeToolbar(onClose: @escaping () -> Void) -> some View {
        modifier(AccessCodeToolbar(onClose: onClose))
    }
}

private struct AccessCodeToolbar: ViewModifier {
    let onClose: () -> Void

    @EnvironmentObject private var style: TangemSdkStyle
    @Environment(\.accessCodeFlow) private var accessCodeFlow
    @Environment(\.accessCodeScreen) private var accessCodeScreen

    private var supportScreen: TangemSdkScreen? {
        guard let accessCodeFlow, accessCodeFlow.isSupportAvailable else { return nil }

        return accessCodeScreen
    }

    func body(content: Content) -> some View {
        if accessCodeFlow?.usesNewDesign == true {
            NavigationStack {
                content
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { toolbarItems }
            }
        } else {
            content
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        if #available(iOS 26.0, *) {
            if let supportScreen {
                ToolbarItem(placement: .topBarTrailing) {
                    supportButton(screen: supportScreen)
                }

                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .close, action: onClose)
            }
        } else {
            if let supportScreen {
                ToolbarItem(placement: .topBarTrailing) {
                    supportButton(screen: supportScreen)
                        .tint(style.colors.tint)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                }
                .tint(style.colors.tint)
            }
        }
    }

    private func supportButton(screen: TangemSdkScreen) -> some View {
        Button("common_support".localized) {
            accessCodeFlow?.requestSupport(from: screen)
            onClose()
        }
    }
}
