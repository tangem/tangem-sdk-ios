//
//  InformationScreen.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/30/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit

@available (iOS 13.0, *)
class InformationScreenViewController: UIViewController {
	
	static func instantiateController(transitioningDelegate: UIViewControllerTransitioningDelegate? = nil) -> InformationScreenViewController {
		let storyboard = UIStoryboard(name: "InformationScreen", bundle: .sdkBundle)
		let controller: InformationScreenViewController = storyboard.instantiateViewController(identifier: String(describing: self))
		controller.transitioningDelegate = transitioningDelegate
		controller.modalPresentationStyle = transitioningDelegate == nil ? .fullScreen : .custom
		return controller
	}
	
	enum State {
		case howToScan, spinner, securityDelay, percentProgress
	}
	
	@IBOutlet weak var howToScanContainer: ScanCardAnimatedView!
	@IBOutlet weak var indicatorContainer: UIView!
	@IBOutlet weak var hintLabel: UILabel!
	@IBOutlet weak var indicatorLabel: UILabel!
	
	private(set) var state: State = .howToScan
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissController)))
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		howToScanContainer.startAnimation()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		howToScanContainer.stopAnimation()
	}
	
	func setState(_ state: State, animated: Bool) {
		
	}
	
	@objc private func dismissController() {
		dismiss(animated: true, completion: nil)
	}
	
}
