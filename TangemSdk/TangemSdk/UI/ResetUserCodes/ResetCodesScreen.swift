//
//  ResetCodesScreen.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct ResetCodesScreen: View {
    @EnvironmentObject var viewModel: ResetCodesViewModel
    @EnvironmentObject var style: TangemSdkStyle
    @Environment(\.accessCodeFlow) private var accessCodeFlow

    var body: some View {
        mainView
            .transition(AnyTransition
                .identity
                .combined(with: .opacity))
            .environmentObject(style)
    }

    @ViewBuilder
    private var mainView: some View {
        switch viewModel.viewState {
        case .intro(let request):
            let screen = TangemSdkScreen.resetCodesIntro

            ResetCodesIntroView(completion: { result in
                accessCodeFlow?.deliverTap(for: result, on: screen)
                request.handle(result)
            })
            .accessCodeScreen(screen, flow: accessCodeFlow)

        case .requestCode(let request):
            let screen = ResetPinService.State.needCode.analyticsScreen

            ChangeUserCodeView(
                type: request.type,
                title: request.type.enterNewCodeTitle,
                cardId: request.cardId ?? "",
                placeholder: request.type.name,
                confirmationPlaceholder: request.type.confirmCodeTitle,
                completion: { result in
                    accessCodeFlow?.deliverTap(for: result, on: screen)
                    request.handle(result)
                }
            )
            .accessCodeScreen(screen, flow: accessCodeFlow)

        case .resetCodes(let request):
            let screen = request.state.analyticsScreen

            ResetUserCodesView(
                title: request.type.resetCodeTitle,
                cardId: request.cardId ?? "",
                card: request.state.cardType,
                messageTitle: request.state.messageTitle,
                messageBody: request.state.messageBody,
                completion: { result in
                    accessCodeFlow?.deliverTap(for: result, on: screen)
                    request.handle(result)
                }
            )
            .accessCodeScreen(screen, flow: accessCodeFlow)

        case .success(let request):
            let screen = request.state.analyticsScreen

            ResetCodesSuccessView(
                title: request.state.messageTitle,
                message: request.state.messageBody,
                onFinish: {
                    accessCodeFlow?.deliver(.buttonTapped(.finish, screen: screen))
                    request.handle(.success(false))
                }
            )
            .accessCodeScreen(screen, flow: accessCodeFlow)

        case .empty:
            EmptyView()
        }
    }
}

// MARK: - Previews

#Preview {
    ResetCodesScreen()
        .environmentObject(ResetCodesViewModel(viewState: .empty))
        .environmentObject(TangemSdkStyle())
}
