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
    
    var cardColor: Color {
        .init(.sRGB,
              red: 0.164705882353,
              green: 0.196078431373,
              blue: 0.274509803922,
              opacity: 1)
    }
    
    var chipColor: Color {
        .init(.sRGB,
              red: 0.901960784314,
              green: 0.929411764706,
              blue: 0.945098039216,
              opacity: 1)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(cardColor)
                
                let chipWidth = 0.15 * geo.size.width
                let chipHeight = 0.7 * chipWidth
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(chipColor)
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
        CardView()
            .frame(width: 300, height: 200)
    }
}
