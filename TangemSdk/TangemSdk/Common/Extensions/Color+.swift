//
//  Color+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
extension Color {
    static func adaptiveColor(dark: UIColor, light: UIColor) -> Color {
        Color(UIColor.init { $0.userInterfaceStyle == .dark ? dark : light })
    }
}
