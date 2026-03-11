//
//  ResetPinTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class ResetPinTask: CardSessionRunnable {
    var preflightReadMode: PreflightReadMode { .readCardOnly }
    var shouldAskForAccessCode: Bool { false }

    private let confirmationCard: ConfirmationCard
    private let accessCode: Data
    private let passcode: Data

    init(confirmationCard: ConfirmationCard, accessCode: Data, passcode: Data) {
        self.confirmationCard = confirmationCard
        self.accessCode = accessCode
        self.passcode = passcode
    }

    deinit {
        Log.debug("ResetPinTask deinit")
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        let prepareCommand = AuthorizeResetPinTokenCommand(confirmationCard: confirmationCard)
        prepareCommand.run(in: session) { prepareResult in
            switch prepareResult {
            case .success:

                let resetCommand = ResetPinCommand(accessCode: self.accessCode, passcode: self.passcode)
                resetCommand.run(in: session) { resetCommandResult in
                    switch resetCommandResult {
                    case .success(let resetCommandResponse):
                        if let card = session.environment.card, card.firmwareVersion < .v8 {
                            completion(.success(resetCommandResponse))
                            return
                        }

                        let manageCommand = ManageAccessTokensCommand(mode: .renew)
                        manageCommand.run(in: session) { _ in
                            completion(.success(resetCommandResponse))
                            withExtendedLifetime(manageCommand) {}
                        }

                    case .failure(let error):
                        completion(.failure(error))
                    }

                    withExtendedLifetime(resetCommand) {}
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

