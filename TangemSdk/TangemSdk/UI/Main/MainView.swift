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
    var state: SessionViewState = .scan
    var indicatorSize: CGSize = .init(width: 240, height: 240)
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            mainView
                .transition(.opacity)

            Spacer()
            
            Color.clear.frame(height: 380)
        }
    }
    
    @ViewBuilder
    var mainView: some View {
        switch state {
        case .default:
            NFCFieldView(isAnimationOn: true)
                .frame(width: indicatorSize.width, height: indicatorSize.height)
            
        case .delay(let currentDelay, let totalDelay):
            DelayView(currentDelay: currentDelay, totalDelay: totalDelay)
                .frame(width: indicatorSize.width, height: indicatorSize.height)
            
        case .progress(let progress):
            ProgressView(circleProgress: progress)
                .frame(width: indicatorSize.width, height: indicatorSize.height)
            
        case .scan:
            ReadView()
                .padding(.top, 40)
        }
    }
}

@available(iOS 13.0, *)
struct MainView_Preview: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
