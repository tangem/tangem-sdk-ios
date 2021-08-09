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
    internal init(currentDelay: CGFloat, totalDelay: CGFloat, bgColor: Color = .lightGray, strokerColor: Color = .tngBlue) {
        self.currentDelay = currentDelay
        self.totalDelay = totalDelay
        self.bgColor = bgColor
        self.strokerColor = strokerColor
        self.animatedDelay = 1.0 - (totalDelay - currentDelay)/totalDelay
    }
    
    var currentDelay: CGFloat {
        didSet {
            animatedDelay = targetDelay
        }
    }
    let totalDelay: CGFloat
    var bgColor: Color = .lightGray
    var strokerColor: Color = .tngBlue
    
    private var targetDelay: CGFloat {
        1.0 - (totalDelay - currentDelay)/totalDelay - 1.0/totalDelay
    }
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    @State private var animatedDelay: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(bgColor, lineWidth: 15)
            
            Circle()
                .trim(from: 0, to: animatedDelay)
                .stroke(strokerColor, lineWidth: 15)
                .rotationEffect(Angle(degrees: -90))
                .animation(.linear(duration: 0.9))
            
            CounterView(currentDelay: Int(currentDelay),
                        totalDelay: Int(totalDelay))
        }
        .onReceive(timer, perform: { time in
            if animatedDelay != targetDelay {
                animatedDelay = targetDelay
            }
            print(time)
            if animatedDelay <= 0 {
                timer.upstream.connect().cancel()
            }
        })
    }
}

@available(iOS 13.0, *)
struct DelayView_Previews: PreviewProvider {
    static var previews: some View {
        DelayView(currentDelay: 4, totalDelay: 5)
            .frame(width: 200, height: 200)
    }
}
