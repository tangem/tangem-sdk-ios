//
//  ResetCodesSuccessView.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct ResetCodesSuccessView: View {
    let title: String
    let message: String
    let onFinish: () -> Void

    @EnvironmentObject var style: TangemSdkStyle

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Image("reset_codes_success", bundle: .sdkBundle)
                    .frame(width: 76, height: 76)

                VStack(spacing: 12) {
                    Text(title)
                        .font(.system(size: 28, weight: .bold))

                    Text(message)
                        .font(.system(size: 16))
                        .foregroundColor(style.colors.secondaryText)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            SdkButton(
                title: "common_finish".localized,
                colors: style.colors.buttonColors,
                action: onFinish
            )
        }
        .padding(.top, 60)
        .padding([.horizontal, .bottom])
    }
}

// MARK: - Previews

#Preview {
    Group {
        ResetCodesSuccessView(
            title: "New Access Code is set",
            message: "The new code will only apply to your device •• 0000. You can change it on your other devices later in Settings.",
            onFinish: {}
        )
        ResetCodesSuccessView(
            title: "New Access Code is set",
            message: "The new code will only apply to this device. You can change it on your other devices later in Settings.",
            onFinish: {}
        )
        .preferredColorScheme(.dark)
    }
    .environmentObject(TangemSdkStyle())
}
