//
//  ResetCodesScreen.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.11.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct ResetCodesScreen: View {
    @EnvironmentObject var viewModel: ResetCodesViewModel
    @EnvironmentObject var style: TangemSdkStyle

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
        case .requestCode(let request):
            ChangeUserCodeView(
                type: request.type,
                title: request.type.enterNewCodeTitle,
                cardId: request.cardId ?? "",
                placeholder: request.type.name,
                confirmationPlaceholder: request.type.confirmCodeTitle,
                completion: request.handle
            )

        case .resetCodes(let request):
            ResetUserCodesView(
                title: request.type.resetCodeTitle,
                cardId: request.cardId ?? "",
                card: request.state.cardType,
                messageTitle: request.state.messageTitle,
                messageBody: request.state.messageBody,
                completion: request.handle
            )

        default:
            EmptyView()
        }
    }
}

struct ResetUserCodesScreen_Preview: PreviewProvider {
    static var previews: some View {
        ResetCodesScreen()
            .environmentObject(ResetCodesViewModel(viewState: .empty))
            .environmentObject(TangemSdkStyle())
    }
}
