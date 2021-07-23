//
//  CounterView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct CounterView: View {
    var currentDelay: CGFloat = 30.0
    var totalDelay: CGFloat = 30.0
    var textSize: CGFloat = 34
    var foregroundColor: Color = .tngBlue
    
    private var itemHeight: CGFloat { textSize + 8 }
    
    var body: some View {
        ZStack {
            
            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<Int(totalDelay)) { index in
                        Text("\(Int(index))")
                            .font(.system(size: textSize,
                                          weight: .medium,
                                          design: .default)
                                    .monospacedDigit())
                            .foregroundColor(foregroundColor)
                            .frame(height: itemHeight)
                    }
                }
                .offset(y: totalDelay * itemHeight / 2 - itemHeight/2)
                .offset(y: -CGFloat(currentDelay) * itemHeight)
                .animation(.spring(dampingFraction: 0.6).speed(2))
            }
            .frame(width: 100, height: itemHeight)
            .clipped()
        }
        //        .onAppear {
        //            _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
        //                withAnimation() {
        //                    self.currentDelay -= 1
        //
        //                    if self.currentDelay == 0 {
        //                        timer.invalidate()
        //                    }
        //                }
        //            }
        //        }
    }
}

@available(iOS 13.0, *)
struct CounterView_Previews: PreviewProvider {
    static var previews: some View {
        CounterView()
    }
}
