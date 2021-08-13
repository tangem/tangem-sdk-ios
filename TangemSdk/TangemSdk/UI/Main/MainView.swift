//
//  ProgressView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct MainView: View {
    var style: TangemSdkStyle
    var state: ViewState = .scan
    var indicatorSize: CGSize = .init(width: 240, height: 240)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            mainView
                .transition(.opacity)
                .environmentObject(style)
            
            if !state.isFullScreen {
                Spacer()
                Color.clear.frame(height: 380)
            }
        }
    }
    
    @ViewBuilder
    var mainView: some View {
        switch state {
        case .default:
            NFCFieldView(isAnimationOn: true)
                .frame(width: indicatorSize.width, height: indicatorSize.height)
            
        case .delay(let remaining, let total, let label):
            DelayView(currentValue: CGFloat(remaining),
                      totalValue: CGFloat(total),
                      labelValue: CGFloat(label))
                .frame(width: indicatorSize.width, height: indicatorSize.height)
            
        case .progress(let progress):
            ProgressView(circleProgress: progress)
                .frame(width: indicatorSize.width, height: indicatorSize.height)
            
        case .scan:
            ReadView()
                .padding(.top, 40)
        case .requestCode(let type, cardId: let cardId, completion: let completion):
            EnterUserCodeView(title: type.enterCodeTitle,
                              cardId: cardId,
                              placeholder: type.name,
                              completion: completion)
        case .requestCodeChange(let type, cardId: let cardId, completion: let completion):
            ChangeUserCodeView(title: type.changeCodeTitle,
                              cardId: cardId,
                              placeholder: type.name,
                              confirmationPlaceholder: type.confirmCodeTitle,
                              completion: completion)
        }
    }
}

@available(iOS 13.0, *)
extension MainView {
    enum ViewState {
        case delay(remaining: Float, total: Float, label: Float) //seconds
        case progress(percent: Int)
        case `default`
        case scan
        case requestCode(_ type: UserCodeType, cardId: String, completion: ((_ code: String?) -> Void))
        case requestCodeChange(_ type: UserCodeType, cardId: String, completion: ((_ code: String?) -> Void))
        
        var isFullScreen: Bool {
            switch self {
            case .requestCode, .requestCodeChange:
                return true
            default:
                return false
            }
        }
    }
}

@available(iOS 13.0, *)
struct MainView_Preview: PreviewProvider {
    static var previews: some View {
        MainView(style: .default)
    }
}
