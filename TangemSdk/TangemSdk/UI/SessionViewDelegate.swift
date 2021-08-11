//
//  SessionViewDelegate.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

/// Allows interaction with users and shows visual elements.
/// Its default implementation, `DefaultSessionViewDelegate`, is in our SDK.
@available(iOS 13.0, *)
public protocol SessionViewDelegate: AnyObject {
    func showAlertMessage(_ text: String)
    
    /// It is called when a user is expected to enter user code.
    func requestUserCode(type: UserCodeType, cardId: String?, completion: @escaping (_ code: String?) -> Void)
    
    /// It is called when a user is expected to change  user code.
    func requestUserCodeChange(type: UserCodeType, cardId: String?, completion: @escaping CompletionResult<(currentCode: String, newCode: String)>)
    
    /// It is called when tag was found
    func tagConnected()
    
    /// It is called when tag was lost
    func tagLost()
    
    func wrongCard(message: String?)
    
    func sessionStarted()
    
    func sessionStopped(completion: (() -> Void)?)
    
    func setConfig(_ config: Config)
    
    func attestationDidFail(isDevelopmentCard: Bool, onContinue: @escaping () -> Void, onCancel: @escaping () -> Void)
    
    func attestationCompletedWithWarnings(onContinue: @escaping () -> Void)
    
    func attestationCompletedOffline(onContinue: @escaping () -> Void, onCancel: @escaping () -> Void, onRetry: @escaping () -> Void)
    
    func setState(_ state: SessionViewState)
}

public enum SessionViewState: Equatable {
    case delay(remaining: Float, total: Float) //seconds
    case progress(percent: Int)
    case `default`
    case scan
    
    var shouldPlayHaptics: Bool {
        switch self {
        case .delay, .progress:
            return true
        default:
            return false
        }
    }
}
