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
    //todo: remove
    @nonobjc class var deepSkyBlue: UIColor {
        return UIColor(red: 0.0, green: 122.0 / 255.0, blue: 1.0, alpha: 1.0)
    }
    
    //todo: remove
    @nonobjc class var tngBlue: UIColor {
        return UIColor(red: 0.0, green: 41.0 / 255.0, blue: 1.0, alpha: 1.0)
    }
}


extension UIColor {
    struct LightPalette {
        static var tint: UIColor {
            .init(red: 0.0,
                  green: 41.0/255.0,
                  blue: 1.0,
                  alpha: 1.0)
        }
        
        static var errorTint: UIColor {
            .init(red: 1.0,
                  green: 69.0/255.0,
                  blue: 58.0/255.0,
                  alpha: 1.0)
        }
        
        static var smallCircleColor: UIColor {
            .init(red: 213.0/255.0,
                  green: 218.0/255.0,
                  blue: 221.0/255.0,
                  alpha: 0.9)
        }
        
        static var bigCircleColor: UIColor {
            .init(red: 240.0/255.0,
                  green: 241.0/255.0,
                  blue: 242.0/255.0,
                  alpha: 0.9)
        }
        
        static var indicatorBackground: UIColor {
            .init(red: 240.0/255.0,
                  green: 241.0/255.0,
                  blue: 242.0/255.0,
                  alpha: 0.9)
        }
        
        static var cardColor: UIColor {
            .init(red: 0.164705882353,
                  green: 0.196078431373,
                  blue: 0.274509803922,
                  alpha: 1)
        }
        
        static var cardChipColor: UIColor {
            .init(red: 0.901960784314,
                  green: 0.929411764706,
                  blue: 0.945098039216,
                  alpha: 1)
        }
    }
}

extension UIColor {
    enum DarkPalette {}
}
