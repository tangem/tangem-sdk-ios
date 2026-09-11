//
//  MainScreen.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainScreen: View {
    @EnvironmentObject var viewModel: MainViewModel
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
        Group {
            switch viewModel.viewState {
            case .scan:
                ReadView()
                    .transition(.opacity.animation(.easeInOut))

            case .requestCode(let request):
                requestCodeView(request: request)

            case .requestCodeChange(let request):
                ChangeUserCodeView(
                    type: request.type,
                    title: request.type.changeCodeTitle,
                    cardId: request.cardId ?? "",
                    placeholder: request.type.enterNewCodeTitle,
                    confirmationPlaceholder: request.type.confirmCodeTitle,
                    completion: request.handle
                )
                .transition(.opacity.animation(.easeInOut))

            case .empty:
                EmptyView()

            default:
                indicatorView(viewModel.viewState.indicatorState!)
                    .transition(.opacity.animation(.easeInOut))
            }
        }
    }

    @ViewBuilder
    private func requestCodeView(request: UserCodeRequest) -> some View {
        if request.showWelcomeBackWarning {
            WelcomeBackView { result in
                viewModel.handleWelcomeBackResult(request: request, result: result)
            }
            .transition(.opacity.animation(.easeInOut))
        } else {
            EnterUserCodeView(
                title: request.type.enterCodeTitle,
                cardId: request.cardId ?? "",
                placeholder: request.type.name,
                showForgotButton: request.showForgotButton,
                completion: request.handle
            )
            .transition(.opacity.animation(.easeInOut))
        }
    }

    @ViewBuilder
    private func indicatorView(_ state: IndicatorView.ViewState) -> some View {
        GeometryReader { geo in

            let sheetHeight = UIScreen.main.isZoomedMode && UIScreen.main.scale < 3 ? Constants.nfcSheetHeightZoomed : Constants.nfcSheetHeight
            let availableSpace = min(geo.size.width, geo.size.height - sheetHeight, Constants.indicatorMaxSize)
            let indicatorSize = availableSpace * 0.8

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    IndicatorView(state: state)
                        .frame(width: indicatorSize, height: indicatorSize)
                    Spacer()
                }
                Spacer()
            }
            .padding(.bottom, sheetHeight)
        }
    }
}

private extension MainScreen {
    enum Constants {
        static let indicatorMaxSize: CGFloat = 280
        static let nfcSheetHeightZoomed: CGFloat = 310 // iPhone 7
        static let nfcSheetHeight: CGFloat = 390
    }
}

// MARK: - Previews

#Preview {
    MainScreen()
        .environmentObject(MainViewModel(viewState: .scan))
        .environmentObject(TangemSdkStyle())
}

private extension SessionViewState {
    var indicatorState: IndicatorView.ViewState? {
        switch self {
        case .default:
            return .spinner

        case .delay(let remaining, let total):
            return .delay(
                currentValue: CGFloat(remaining),
                totalValue: CGFloat(total)
            )

        case .progress(let progress):
            return .progress(progress: progress)

        default:
            return nil
        }
    }
}
