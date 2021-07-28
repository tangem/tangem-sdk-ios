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
    let currentDelay: Int
    let totalDelay: Int

    var bgColor: Color = .lightGray
    var strokerColor: Color = .tngBlue
    
    private var normalizedDelay: CGFloat {
        1.0 - CGFloat(totalDelay - currentDelay)/CGFloat(totalDelay)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(bgColor, lineWidth: 15)
            
            Circle()
                .trim(from: 0, to: normalizedDelay)
                .stroke(strokerColor, lineWidth: 15)
                .rotationEffect(Angle(degrees: -90))
                .animation(.linear(duration: 1.0))
            
            CounterView(currentDelay: currentDelay + 1,
                        totalDelay: totalDelay)
        }
    }
}

@available(iOS 13.0, *)
struct DelayView_Previews: PreviewProvider {
    static var previews: some View {
        DelayView(currentDelay: 4, totalDelay: 5)
            .frame(width: 200, height: 200)
    }
}
