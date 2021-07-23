//
//  DelayView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct DelayView: View {
    var currentDelay: CGFloat = 0
    var totalDelay: CGFloat = 0
    
    var bgColor: Color = .lightGray
    var strokerColor: Color = .tngBlue
    
    private var normalizedDelay: CGFloat {
        1 - (totalDelay - currentDelay)/totalDelay
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(bgColor, lineWidth: 15)
            
            Circle()
                .trim(from: 0.0, to: normalizedDelay)
                .stroke(strokerColor, lineWidth: 15)
                .rotationEffect(Angle(degrees: -90))
                .animation(.spring(dampingFraction: 0.6)
                            .speed(2))
            
            CounterView(currentDelay: currentDelay,
                        totalDelay: totalDelay)
        }
//        .onAppear {
//            _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
//                withAnimation() {
//                    self.currentDelay -= 1
//                    if self.currentDelay == 0 {
//                        timer.invalidate()
//                    }
//                }
//            }
//        }
    }
}

@available(iOS 13.0, *)
struct DelayView_Previews: PreviewProvider {
    static var previews: some View {
        DelayView()
            .frame(width: 200, height: 200)
    }
}
