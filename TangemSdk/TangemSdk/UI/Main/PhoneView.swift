//
//  PhoneView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct PhoneView: View {
    
    var strokeColor: Color {
        .init(.sRGB,
              red: 0.164705882353,
              green: 0.196078431373,
              blue: 0.274509803922,
              opacity: 1)
    }
    
    var capsuleHeight: CGFloat = 40
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 35)
                    .inset(by: 4)
                    .stroke(Color.black, lineWidth: 14)
                    .background(Color.white
                                    .opacity(0.955))
                    .clipShape(RoundedRectangle(cornerRadius:35))
                
                Capsule(style: .continuous)
                    .fill(Color.black)
                    .frame(width: 0.5 * geo.size.width,
                           height: capsuleHeight)
                    .clipShape(Rectangle().offset(y: capsuleHeight/2))
                    .offset(y: -geo.size.height/2)
            }
        }
    }
}

@available(iOS 13.0, *)
struct PhoneView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneView().padding(50)
    }
}
