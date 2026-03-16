//
//  ResetPinViewModel.swift
//  TangemSdkExample
//
//  Created by Alexander Osokin on 03.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemSdk
import UIKit

@MainActor
final class ResetPinViewModel: ObservableObject {
    @Published var accessCode: String = ""
    @Published var passcode: String = ""
    @Published var errorText: String = ""

    @Published private(set) var stateTitle: String = ""
    @Published private(set) var serviceErrorText: String? = nil

    var isSetUp: Bool { resetPinService != nil }

    private var resetPinService: ResetPinService?
    private var bag: Set<AnyCancellable> = []

    init() {}

    func setup(resetPinService: ResetPinService) {
        guard !isSetUp else { return }
        self.resetPinService = resetPinService
        bind()
    }

    func setAccessCode() {
        do {
            try resetPinService?.setAccessCode(accessCode)
            errorText = ""
            UIApplication.shared.endEditing()
        } catch {
            errorText = "Error occurred: \(error)"
        }
    }

    func setPasscode() {
        do {
            try resetPinService?.setPasscode(passcode)
            errorText = ""
            UIApplication.shared.endEditing()
        } catch {
            errorText = "Error occurred: \(error)"
        }
    }

    func proceed() {
        resetPinService?.proceed()
    }

    private func bind() {
        guard let resetPinService else { return }

        resetPinService.currentStatePublisher
            .sink { [weak self] state in
                guard let self else { return }
                self.stateTitle = "Current state is: \(state)"
            }
            .store(in: &bag)

        resetPinService.errorPublisher
            .sink { [weak self] _ in
                guard let self else { return }
                self.serviceErrorText = self.resetPinService?.error.map { "Error occurred: \($0.localizedDescription)" }
            }
            .store(in: &bag)
    }
}
