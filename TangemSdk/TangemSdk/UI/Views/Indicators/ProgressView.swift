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
    var circleProgress: Int = 0
    
    @EnvironmentObject var style: TangemSdkStyle
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(style.colors.indicatorBackground, lineWidth: 15)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(circleProgress)/100.0)
                .stroke(style.colors.tint, lineWidth: 15)
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeIn)
            
            Text("\(self.circleProgress)%")
                .font(Font.system(size: style.textSizes.indicatorLabel,
                              weight: .medium,
                              design: .default)
                        .monospacedDigit())
                .foregroundColor(style.colors.tint)
        }
    }
}

@available(iOS 13.0, *)
struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProgressView(circleProgress: 10)
                .padding()

            ProgressView(circleProgress: 10)
                .preferredColorScheme(.dark)
                .padding()
        }
        .environmentObject(TangemSdkStyle())
    }
}
