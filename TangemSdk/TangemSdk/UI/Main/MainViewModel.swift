//
//  MainViewModel.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.11.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

typealias MainViewModel = ViewModel<SessionViewState>

extension MainViewModel {
    func handleWelcomeBackResult(request: UserCodeRequest, result: Result<Bool, TangemSdkError>) {
        switch result {
        case .success(true):
            request.acknowledgeWelcomeBack()
            viewState = .requestCode(request)
        case .success(false), .failure:
            request.cancel()
        }
    }
}
