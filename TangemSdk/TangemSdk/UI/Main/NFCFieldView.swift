//
//  NFCFieldView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct NFCFieldView: View {
    var isAnimationOn: Bool {
        didSet {
            circleScale = isAnimationOn ? 0.5 : 1
        }
    }
    
    let duration: Double = 0.9
    
    var smallCircleColor: Color {
        .init(.sRGB,
              red: 213.0/255.0,
              green: 218.0/255.0,
              blue: 221.0/255.0,
              opacity: 0.9)
    }
    
    var bigCircleColor: Color {
        .init(.sRGB,
              red: 240.0/255.0,
              green: 241.0/255.0,
              blue: 242.0/255.0,
              opacity: 0.9)
    }
    
    var bigCircleAnimation: Animation {
        .easeInOut(duration: duration)
            .repeatForever()
            .delay(0.1)
    }
    
    var smallCircleAnimation: Animation {
        .easeInOut(duration: duration)
            .repeatForever()
    }
    
    @State private var circleScale: CGFloat =  1.0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(bigCircleColor)
                    .scaleEffect(circleScale)
                    .animation(isAnimationOn ? bigCircleAnimation : nil)
                
                Circle()
                    .fill(smallCircleColor)
                    .frame(width: 0.6 * geo.size.width,
                           height: 0.6 * geo.size.width)
                    .scaleEffect(circleScale)
                    .animation(isAnimationOn ? smallCircleAnimation : nil)
            }
        }
        .onAppear() {
            circleScale = isAnimationOn ? 0.5 : 1
        }
    }
}

@available(iOS 13.0, *)
struct NFCView_Previews: PreviewProvider {
    @State static var animation: Bool = true
    static var previews: some View {
        NFCFieldView(isAnimationOn: animation)
    }
}
