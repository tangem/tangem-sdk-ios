//
//  UIScreen+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

extension UIScreen {
    var isZoomedMode: Bool { UIScreen.main.scale != UIScreen.main.nativeScale }
}
