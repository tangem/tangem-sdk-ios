//
//  UIButton_.swift
//  TangemSdkExample
//
//  Created by Alexander Osokin on 02.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
