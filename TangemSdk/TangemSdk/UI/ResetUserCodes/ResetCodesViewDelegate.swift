//
//  ResetCodesViewDelegate.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

protocol ResetCodesViewPresenting: AnyObject {
    func setState(_ state: ResetCodesViewState)
    func hide(completion: (() -> Void)?)
    func showError(_ error: TangemSdkError)
    func showAlert(_ title: String, message: String, onContinue: @escaping () -> Void)
}

final class ResetCodesViewDelegate: BaseViewDelegate, ResetCodesViewPresenting {
    private let viewModel: ResetCodesViewModel = .init(viewState: .empty)
    private let style: TangemSdkStyle
    private let accessCodeFlow: AccessCodeFlow
    private lazy var sheetDismissHandler = SheetDismissHandler { [weak self] in
        guard case .intro(let request) = self?.viewModel.viewState else { return }

        request.handle(.failure(.userCancelled))
    }

    init(style: TangemSdkStyle, accessCodeFlow: AccessCodeFlow) {
        self.style = style
        self.accessCodeFlow = accessCodeFlow
    }

    override func makeScreen() -> UIViewController {
        let view = ResetCodesScreen()
            .environmentObject(viewModel)
            .environmentObject(style)
            .environment(\.accessCodeFlow, accessCodeFlow)

        let screen = UIHostingController(rootView: view)
        screen.isModalInPresentation = true

        if accessCodeFlow.usesNewDesign {
            screen.modalPresentationStyle = .pageSheet
            screen.sheetPresentationController?.detents = [.large()]
            screen.presentationController?.delegate = sheetDismissHandler
            updateSwipeDismiss(of: screen)
        }

        return screen
    }

    override func presentationDidFail() {
        // A prompt nobody can see would keep the whole reset flow and its session alive forever
        switch viewModel.viewState {
        case .intro(let request):
            request.handle(.failure(.userCancelled))
        case .requestCode(let request):
            request.cancel()
        case .resetCodes(let request):
            request.handle(.failure(.userCancelled))
        case .success(let request):
            request.handle(.success(false))
        case .empty:
            break
        }
    }

    func setState(_ state: ResetCodesViewState) {
        Log.view("Set state: \(state)")

        let setStateAction = {
            self.viewModel.viewState = state
            if self.accessCodeFlow.usesNewDesign, let screen = self.screen {
                self.updateSwipeDismiss(of: screen)
            }
        }
        runInMainThread(setStateAction())
        runInMainThread(self.presentScreenIfNeeded())
    }

    func hide(completion: (() -> Void)?) {
        runInMainThread(self.dismissScreen(completion: completion))
    }

    func showError(_ error: TangemSdkError) {
        guard let screen = screen else { return }

        let tint = style.colors.tintUIColor
        runInMainThread(UIAlertController.showAlert(
            from: screen,
            title: "common_error".localized,
            message: error.localizedDescription,
            tint: tint,
            onContinue: {}
        ))
    }

    func showAlert(_ title: String, message: String, onContinue: @escaping () -> Void) {
        guard let screen = screen else {
            onContinue()
            return
        }

        let tint = style.colors.tintUIColor
        runInMainThread(UIAlertController.showAlert(
            from: screen,
            title: title,
            message: message,
            tint: tint,
            onContinue: onContinue
        ))
    }

    /// Only the intro may be swiped away; a swipe mid-reset would leave the card half-done
    private func updateSwipeDismiss(of screen: UIViewController) {
        if case .intro = viewModel.viewState {
            screen.isModalInPresentation = false
        } else {
            screen.isModalInPresentation = true
        }
    }
}

private final class SheetDismissHandler: NSObject, UIAdaptivePresentationControllerDelegate {
    private let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onDismiss()
    }
}
