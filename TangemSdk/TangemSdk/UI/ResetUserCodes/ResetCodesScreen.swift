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

    private var usesNewDesign: Bool {
        accessCodeFlow?.usesNewDesign == true
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
            let copy = ResetCodesCopy(type: request.type, cardId: request.cardId)

            ChangeUserCodeView(
                type: request.type,
                title: usesNewDesign ? copy.newCodeTitle : request.type.enterNewCodeTitle,
                cardId: request.cardId ?? "",
                placeholder: usesNewDesign ? copy.codePlaceholder : request.type.name,
                confirmationPlaceholder: usesNewDesign ? copy.confirmationPlaceholder : request.type.confirmCodeTitle,
                subtitle: usesNewDesign ? copy.newCodeSubtitle : nil,
                completion: { result in
                    accessCodeFlow?.deliverTap(for: result, on: screen)
                    request.handle(result)
                }
            )
            .accessCodeScreen(screen, flow: accessCodeFlow)

        case .resetCodes(let request):
            let screen = request.state.analyticsScreen
            let copy = ResetCodesCopy(type: request.type, cardId: request.cardId)

            ResetUserCodesView(
                title: request.type.resetCodeTitle,
                cardId: request.cardId ?? "",
                card: request.state.cardType,
                messageTitle: usesNewDesign ? copy.stepTitle(for: request.state) : request.state.messageTitle,
                messageBody: usesNewDesign ? copy.stepBody(for: request.state) : request.state.messageBody,
                completion: { result in
                    accessCodeFlow?.deliverTap(for: result, on: screen)
                    request.handle(result)
                }
            )
            .accessCodeScreen(screen, flow: accessCodeFlow)

        case .success(let request):
            let screen = request.state.analyticsScreen
            let copy = ResetCodesCopy(type: request.type, cardId: request.cardId)

            ResetCodesSuccessView(
                title: copy.successTitle,
                message: copy.successBody,
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
