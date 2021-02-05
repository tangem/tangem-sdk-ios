//
//  CardReader.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 26/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC
import Combine

public enum NFCTagType: Equatable {
    case tag(uid: Data)
    case slix2
    case unknown
}

/// Allows interaction between the phone or any other terminal and Tangem card.
/// Its default implementation, `NfcReader`, is in our module.
public protocol CardReader: class {
	/// For setting alertMessage into NFC popup
    var alertMessage: String { get set }
    @available(iOS 13.0, *)
    var tag: CurrentValueSubject<NFCTagType?,TangemSdkError> { get }
	@available (iOS 13.0, *)
	var isSessionReady: CurrentValueSubject<Bool, Never> { get }
    func startSession(with message: String?)
    func resumeSession()
    func stopSession(with errorMessage: String?)
    func pauseSession(with errorMessage: String?)
    @available(iOS 13.0, *)
    func sendPublisher(apdu: CommandApdu) -> AnyPublisher<ResponseApdu, TangemSdkError>
    func readSlix2Tag(completion: @escaping (Result<ResponseApdu, TangemSdkError>) -> Void) 
    func restartPolling()
}

public extension CardReader {
    func startSession(with message: String? = nil) {
        startSession(with: message)
    }
    
    func stopSession(with errorMessage: String? = nil) {
        stopSession(with: errorMessage)
    }
}
