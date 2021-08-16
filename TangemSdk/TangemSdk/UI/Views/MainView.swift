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
    let style: TangemSdkStyle
    var viewState: ViewState = .scan
    
    var body: some View {
        mainView
            .transition(.identity.combined(with: .opacity))
            .environmentObject(style)
    }
    
    @ViewBuilder
    var mainView: some View {
        switch viewState {
        case .default:
            SpinnerView()
                .frame(width: style.indicatorSize, height: style.indicatorSize)
                .padding(.top, 40)
                .padding(.bottom, 360)
            
        case .delay(let remaining, let total, let label):
            DelayView(currentValue: CGFloat(remaining),
                      totalValue: CGFloat(total),
                      labelValue: CGFloat(label))
                .frame(width: style.indicatorSize, height: style.indicatorSize)
                .padding(.top, 40)
                .padding(.bottom, 360)
            
        case .progress(let progress):
            ProgressView(circleProgress: progress)
                .frame(width: style.indicatorSize, height: style.indicatorSize)
                .padding(.top, 40)
                .padding(.bottom, 360)
            
        case .scan:
            ReadView()
                .padding(.bottom, 60)
            
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
    @available(iOS 13.0, *) //fix preview bug
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
