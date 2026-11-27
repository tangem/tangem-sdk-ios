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
            FillingScrollView { _ in
                VStack(spacing: 12) {
                    Image(decorative: "reset_codes_intro", bundle: .sdkBundle)
                        .renderingMode(.template)
                        .foregroundColor(.primary)
                        .frame(width: 80, height: 80)

                    Text("reset_codes_btn_forgot_your_code".localized)
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
            }

            SdkButton(
                title: "common_continue".localized,
                colors: style.colors.buttonColors,
                action: onContinue
            )
        }
        .padding([.horizontal, .bottom])
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
