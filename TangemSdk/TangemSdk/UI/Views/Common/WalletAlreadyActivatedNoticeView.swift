//
//  WalletAlreadyActivatedNoticeView.swift
//  TangemSdk
//
//  Created by Sergey Balashov on 10.04.2026.
//

import SwiftUI

struct WalletAlreadyActivatedNoticeView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            notification

            SdkButton(
                title: "already_activated_btn_just_bought".localized,
                colors: TangemSdkStyle.ButtonColors.customWhiteColors,
                action: action
            )
        }
        .padding(.all, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: UIColor.LightPalette.warningBackground).opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var notification: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color(uiColor: UIColor.systemYellow))
                .font(.system(size: 20, weight: .semibold))

            Text("tangem_never_pregenerate_code_alert".localized)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private extension TangemSdkStyle.ButtonColors {
    static let customWhiteColors: Self = .init(
        foregroundColor: .adaptiveColor(
            dark: .white,
            light: UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1)
        ),
        backgroundColor: .adaptiveColor(
            dark: .white.withAlphaComponent(0.2),
            light: .white
        ),
        disabledForegroundColor: .adaptiveColor(
            dark: UIColor(red: 73/255, green: 73/255, blue: 73/255, alpha: 1),
            light: UIColor(red: 201/255, green: 201/255, blue: 201/255, alpha: 1)
        ),
        disabledBackgroundColor: .adaptiveColor(
            dark: UIColor(red: 48/255, green: 48/255, blue: 48/255, alpha: 1),
            light: UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
        )
    )
}

#Preview {
    WalletAlreadyActivatedNoticeView {}
}
