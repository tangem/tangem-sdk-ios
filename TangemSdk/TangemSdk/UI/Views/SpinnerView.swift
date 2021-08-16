//
//  SpinnerView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 16.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct SpinnerView: View {
    @EnvironmentObject var style: TangemSdkStyle
    
    @State private var angle = 0.0
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.8)
            .stroke(style.colors.tint, lineWidth: 15)
            .rotationEffect(Angle(degrees: angle))
            .animation(
                Animation.linear(duration: 1)
                    .repeatForever(autoreverses: false)
            )
        .onAppear {
            angle = 360
        }
    }
}

@available(iOS 13.0, *)
struct SpinnerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SpinnerView()
            SpinnerView()
                .preferredColorScheme(.dark)
        }
        .environmentObject(TangemSdkStyle())
    }
}
