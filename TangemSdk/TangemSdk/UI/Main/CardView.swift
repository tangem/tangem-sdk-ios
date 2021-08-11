//
//  CardView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct CardView: View {
    @EnvironmentObject var style: TangemSdkStyle

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(style.colors.cardColor)
                
                let chipWidth = 0.15 * geo.size.width
                let chipHeight = 0.7 * chipWidth
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(style.colors.cardChipColor)
                    .frame(width: chipWidth, height: chipHeight)
                    .offset(x: 1.5 * chipWidth-geo.size.width/2,
                            y: -0.5*chipHeight)
            }
        }
    }
}

@available(iOS 13.0, *)
struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CardView()
                .frame(width: 300, height: 200)
            CardView()
                .preferredColorScheme(.dark)
                .frame(width: 300, height: 200)
        }
        .environmentObject(TangemSdkStyle())
    }
}
