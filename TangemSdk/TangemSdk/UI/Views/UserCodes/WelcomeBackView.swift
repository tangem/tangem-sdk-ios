//
//  WelcomeBackView.swift
//  TangemSdk
//
//  Created by GuitarKitty on 20.02.2026.
//

import SwiftUI

struct WelcomeBackView: View {
    let completion: CompletionResult<Bool>

    @EnvironmentObject var style: TangemSdkStyle
    @State private var showSafari = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                circleIcon
                    .padding(.top, 68)

                VStack(spacing: 12) {
                    Text("already_activated_title".localized)
                        .font(.system(size: 28).bold())
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text("already_activated_message".localized)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                SecurityNoticeView()
                    .padding(.horizontal, 32)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 16) {
            VStack(spacing: 10) {
                SdkButton(
                    title: "already_activated_btn_confirm".localized,
                    colors: style.colors.buttonColors,
                    action: onConfirm
                )

                SdkButton(
                    title: "already_activated_btn_just_bought".localized,
                    colors: style.colors.secondaryButtonColors
                ) {
                    showSafari = true
                }
            }
            .padding(.horizontal, 16)
            .bottomPaddingIfZeroSafeArea(16)
        }
        .sheet(isPresented: $showSafari) {
            if let preactivatedWalletsURL = Constants.preactivatedWalletsURL {
                SafariView(url: preactivatedWalletsURL)
                    .edgesIgnoringSafeArea(.bottom)
            }
        }
    }

    private var circleIcon: some View {
        Image("heading", bundle: .sdkBundle)
            .foregroundColor(style.colors.tint)
            .padding(16)
            .background(style.colors.tint.opacity(0.1))
            .clipShape(Circle())
    }

    private func onConfirm() {
        completion(.success(true))
    }
}

// MARK: - Constants

private extension WelcomeBackView {
    enum Constants {
        static let supportedBlogLanguages: Set<String> = [
            "en", "es", "pt", "de", "ja", "fr", "tr", "ko", "zh-Hans",
        ]

        static var preactivatedWalletsURL: URL? {
            let lang = Locale.languageCode(supportedCodes: supportedBlogLanguages)
            return URL(string: "https://tangem.com/\(lang)/blog/post/preactivated-wallets/")
        }
    }
}

// MARK: - Preview

struct WelcomeBackView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeBackView { _ in }
            .environmentObject(TangemSdkStyle())
    }
}
