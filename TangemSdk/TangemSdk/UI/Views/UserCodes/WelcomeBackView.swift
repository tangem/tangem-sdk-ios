//
//  WelcomeBackView.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
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

                VStack(spacing: 32) {
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

                    WalletAlreadyActivatedNoticeView { showSafari = true }
                        .padding(.horizontal, 16)
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 16) {
            SdkButton(
                title: "already_activated_btn_confirm".localized,
                colors: style.colors.secondaryButtonColors,
                action: onConfirm
            )
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
        Image(systemName: "exclamationmark.shield.fill")
            .foregroundColor(Color(uiColor: UIColor.systemYellow))
            .font(.system(size: 40, weight: .semibold))
            .padding(16)
            .background(Color(uiColor: UIColor.LightPalette.warningBackground).opacity(0.2))
            .clipShape(Circle())
    }

    private func onConfirm() {
        completion(.success(true))
    }
}

// MARK: - Constants

private extension WelcomeBackView {
    enum Constants {
        static var preactivatedWalletsURL: URL? {
            let utmCampaignValue = "articles-sdk-\(Locale.appLanguageCode)"
            let utmContentValue = "devicelang-\(Locale.deviceLanguageCode())"

            let queryItems = [
                URLQueryItem(name: "utm_source", value: "tangem-app"),
                URLQueryItem(name: "utm_medium", value: "app"),
                URLQueryItem(name: "utm_campaign", value: utmCampaignValue),
                URLQueryItem(name: "utm_content", value: utmContentValue),
            ]

            var blogURLComponents = URLComponents(string: "https://tangem.com/embed/blog/post/preactivated-wallets")
            blogURLComponents?.queryItems = queryItems

            return blogURLComponents?.url
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
