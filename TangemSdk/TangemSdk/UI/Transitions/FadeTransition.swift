//
//  FadeTransition.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/30/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit

@available (iOS 13.0, *)
final class FadeTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		FadeInAnimator()
	}
	
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		FadeOutAnimator()
	}
}

class FadeInAnimator: NSObject, UIViewControllerAnimatedTransitioning {

	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return 0.3
	}

	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		guard let toViewController = transitionContext.viewController(forKey: .to) else { return }
		transitionContext.containerView.addSubview(toViewController.view)
		toViewController.view.alpha = 0

		let duration = self.transitionDuration(using: transitionContext)
		UIView.animate(withDuration: duration, animations: {
			toViewController.view.alpha = 1
		}, completion: { _ in
			transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
		})
	}
}

class FadeOutAnimator: NSObject, UIViewControllerAnimatedTransitioning {

	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return 0.3
	}

	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		guard let fromViewController = transitionContext.viewController(forKey: .from) else { return }

		let duration = self.transitionDuration(using: transitionContext)
		UIView.animate(withDuration: duration, animations: {
			fromViewController.view.alpha = 0
		}, completion: { _ in
			transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
		})
	}
}
