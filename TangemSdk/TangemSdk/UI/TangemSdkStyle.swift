//
//  TangemSdkStyle.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
public class TangemSdkStyle: ObservableObject {
    public var colors: Colors = .default
    public var textSizes: TextSizes = .default
    public var indicatorWidth: Float = 12
    
    public static var `default`: TangemSdkStyle = .init()
}

@available(iOS 13.0, *)
public extension TangemSdkStyle {
    struct Colors {
        public var tint: Color = .blue
        
        public var disabledButtonBackground: Color = Color(UIColor.systemGray6)
        
        public var buttonForeground: Color = .white
        
        public var disabledButtonForeground: Color = .gray
        
        public var errorTint: Color = .red
        
        public var indicatorBackground: Color = .adaptiveColor(dark: .darkGray, light: UIColor.LightPalette.indicatorBackground)
        
        public var phoneBackground: Color = .adaptiveColor(dark: .black, light: .white)
        
        public var phoneStroke: Color = .adaptiveColor(dark: .white, light: .black)
        
        public var cardColor: Color = .adaptiveColor(dark: UIColor.DarkPalette.cardColor, light: UIColor.LightPalette.cardColor)
        
        public var starsColor: Color = Color(UIColor.systemGray5) //Card's stars
        
        public static var `default`: Colors = .init()
    }
}

@available(iOS 13.0, *)
public extension TangemSdkStyle {
    struct TextSizes {
        public var indicatorLabel: CGFloat = 50
        
        public static var `default`: TextSizes = .init()
    }
}
