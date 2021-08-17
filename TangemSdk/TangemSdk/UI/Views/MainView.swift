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
    var style: TangemSdkStyle = .default
    var viewState: ViewState = .scan
    
    var body: some View {
        mainView
            .transition(.identity.combined(with: .opacity))
            .environmentObject(style)
    }
    
    @ViewBuilder
    private var mainView: some View {
        switch viewState {
        case .default:
            indicatorView(SpinnerView())
            
        case .delay(let remaining, let total, let label):
            indicatorView(DelayView(currentValue: CGFloat(remaining),
                                    totalValue: CGFloat(total),
                                    labelValue: CGFloat(label)))
            
        case .progress(let progress):
            indicatorView(ProgressView(circleProgress: progress))
            
        case .scan:
            ReadView()
                .padding(.bottom, 20)
            
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
    
    @ViewBuilder
    private func indicatorView<V: View>(_ view: V) -> some View {
        GeometryReader { geo in
            
            let size = geo.size.width * 0.6
            
            HStack(alignment: .center, spacing: 0) {
                
                Spacer()
                
                view
                    .frame(width: size, height: size)
                    .padding(.top, geo.size.height * 0.2)
                
                Spacer()
            }
        }
        .padding(.bottom, 360)
    }
}

@available(iOS 13.0, *)
extension MainView {
    @available(iOS 13.0, *) //fix preview not compile issue
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
        MainView(viewState: .default)
        MainView(viewState: .scan)
    }
}
