//
//  UIViewController.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

import UIKit

extension UIViewController {
    @objc var topmostViewController: UIViewController? {
        let controller = presentedViewController?.topmostViewController ?? self
        
        if let alert = controller as? UIAlertController { //We can't present modally from detached controllers
            return alert.presentingViewController
        }
        
        return controller
    }
}

extension UINavigationController {
    override var topmostViewController: UIViewController? {
        return visibleViewController?.topmostViewController
    }
}

extension UITabBarController {
    override var topmostViewController: UIViewController? {
        return selectedViewController?.topmostViewController
    }
}

extension UIWindow {
    var topmostViewController: UIViewController? {
        return rootViewController?.topmostViewController
    }
}

extension UIApplication {
    var topMostViewController : UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        return keyWindow?.topmostViewController
    }
}
