//
//  UIColor+.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    struct LightPalette {        
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
    }
}

extension UIColor {
    enum DarkPalette {
        static var cardColor: UIColor {
            .init(red: 209.0/255.0,
                  green: 209/255.0,
                  blue: 214.0/255.0,
                  alpha: 1)
        }
    }
}
