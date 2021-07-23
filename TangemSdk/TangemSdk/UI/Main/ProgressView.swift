//
//  ProgressView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct ProgressView: View {
    var circleProgress: CGFloat = 0.0
    var bigCircleColor: Color = .lightGray
    var strokerColor: Color = .tngBlue
    var textSize: CGFloat = 34
    var foregroundColor: Color = .tngBlue
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(bigCircleColor, lineWidth: 15)
            
            Circle()
                .trim(from: 0.0, to: circleProgress)
                .stroke(Color.tngBlue, lineWidth: 15)
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeIn)
            
            Text("\(Int(self.circleProgress*100))%")
                .font(.system(size: textSize,
                              weight: .medium,
                              design: .default)
                        .monospacedDigit())
                .foregroundColor(foregroundColor)
                .animation(nil)
        }
//        .onAppear {
//            _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
//                withAnimation() {
//                    self.circleProgress += 0.01
//                    if self.circleProgress >= 1.0 {
//                        timer.invalidate()
//                    }
//                }
//            }
//        }
    }
}

@available(iOS 13.0, *)
struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressView()
            .padding()
    }
}
