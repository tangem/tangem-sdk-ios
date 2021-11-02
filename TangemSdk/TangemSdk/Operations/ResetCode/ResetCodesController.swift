//
//  ResetCodesController.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 29.10.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13.0, *)
public class ResetCodesController {
    private let resetService: ResetPinService
    private let viewDelegate: ResetCodesViewDelegate
    
    private var bag = Set<AnyCancellable>()
    private var codeType: UserCodeType? = nil
    
    init(resetService: ResetPinService, viewDelegate: ResetCodesViewDelegate) {
        self.resetService = resetService
        self.viewDelegate = viewDelegate
        bind()
    }
    
    deinit {
        Log.debug("ResetCodesController deinit")
    }
    
    public func start(codeType: UserCodeType) {
        self.codeType = codeType
        viewDelegate.setState(.requestCode(codeType, cardId: nil, completion: handleCodeInput))
    }
    
    private func bind() {
        self.resetService
            .$currentState
            .dropFirst()
            .sink {[unowned self] newState in
                switch newState {
                case .finished:
                    self.viewDelegate.showAlert(newState.messageTitle,
                                                message: newState.messageBody,
                                                onContinue: { self.handleContinue(shouldContinue: false) })
                default:
                    if let codeType = self.codeType {
                        self.viewDelegate.setState(.resetCodes(codeType,
                                                               state: newState,
                                                               cardId: self.resetService.resetPinCardId,
                                                               completion: handleContinue))
                    }
                }
            }
            .store(in: &bag)
    }
    
    private func handleCodeInput(code: String?) -> Void {
        guard let code = code else { //user cancelled
            viewDelegate.hide()
            return
        }
        
        do {
            try resetService.setAccessCode(code)
        } catch {
            viewDelegate.showError(error.toTangemSdkError())
        }
    }
    
    private func handleContinue(shouldContinue: Bool) -> Void {
        if !shouldContinue { //user cancelled or finished
            viewDelegate.hide()
            return
        }
        
        resetService.proceed()
    }
}
