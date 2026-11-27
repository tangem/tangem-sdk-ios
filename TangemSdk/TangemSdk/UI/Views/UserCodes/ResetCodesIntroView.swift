//
//  ResetCodesIntroView.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct ResetCodesIntroView: View {
    let completion: CompletionResult<Void>

    @EnvironmentObject var style: TangemSdkStyle

    var body: some View {
        VStack(spacing: 0) {
            AccessCodeToolbar(onCancel: onCancel)
                .padding(.top, 16)

            ScrollView {
                VStack(spacing: 40) {
                    heading

                    VStack(alignment: .leading, spacing: 28) {
                        row(
                            icon: "reset_codes_wallet",
                            title: "reset_codes_intro_backup_title".localized,
                            subtitle: "reset_codes_intro_backup_subtitle".localized
                        )

                        row(
                            icon: "reset_codes_coin_token",
                            title: "reset_codes_intro_assets_title".localized,
                            subtitle: "reset_codes_intro_assets_subtitle".localized
                        )
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.top, 32)
            }
            .scrollBounceBehavior(.basedOnSize)

            SdkButton(
                title: "common_continue".localized,
                colors: style.colors.buttonColors,
                action: onContinue
            )
        }
        .padding([.horizontal, .bottom])
    }

    private var heading: some View {
        VStack(spacing: 12) {
            Image("reset_codes_intro", bundle: .sdkBundle)
                .renderingMode(.template)
                .foregroundColor(.primary)
                .frame(width: 80, height: 80)

            Text("reset_codes_intro_title".localized)
                .font(.system(size: 28, weight: .bold))

            Text("reset_codes_intro_subtitle".localized)
                .font(.system(size: 16))
                .foregroundColor(style.colors.secondaryText)
        }
        .multilineTextAlignment(.center)
    }

    private func row(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(icon, bundle: .sdkBundle)
                .renderingMode(.template)
                .foregroundColor(.primary)
                .frame(width: 42, height: 42)
                .background(Circle().fill(style.colors.secondaryButtonColors.backgroundColor))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))

                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(style.colors.secondaryText)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func onCancel() {
        completion(.failure(.userCancelled))
    }

    private func onContinue() {
        completion(.success(()))
    }
}

// MARK: - Previews

#Preview {
    Group {
        ResetCodesIntroView(completion: { _ in })
        ResetCodesIntroView(completion: { _ in })
            .preferredColorScheme(.dark)
    }
    .environmentObject(TangemSdkStyle())
}
