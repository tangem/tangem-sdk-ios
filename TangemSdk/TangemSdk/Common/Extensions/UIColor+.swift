//
//  UIColor+.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

extension UIColor {
    @nonobjc class var deepSkyBlue: UIColor {
        return UIColor(red: 0.0, green: 122.0 / 255.0, blue: 1.0, alpha: 1.0)
    }
    
    @nonobjc class var tngBlue: UIColor {
       return UIColor(red: 0.0, green: 41.0 / 255.0, blue: 1.0, alpha: 1.0)
    }
}

@available(iOS 13.0, *)
extension Color {
    @nonobjc static var deepSkyBlue: Color {
        return Color(red: 0.0, green: 122.0 / 255.0, blue: 1.0, opacity: 1.0)
    }
    
    @nonobjc static var tngBlue: Color {
       return Color(red: 0.0, green: 41.0 / 255.0, blue: 1.0, opacity: 1.0)
    }
    
    @nonobjc static var lightGray: Color {
       return .init(.sRGB,
                    red: 240.0/255.0,
                    green: 241.0/255.0,
                    blue: 242.0/255.0,
                    opacity: 0.9)
    }
}
