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
//		controller.transitioningDelegate = transitioningDelegate
		controller.modalPresentationStyle = .fullScreen
		return controller
	}
	
	enum State {
		case howToScan, spinner, securityDelay, percentProgress, idle
	}
	
	@IBOutlet weak var howToScanView: ScanCardAnimatedView!
	@IBOutlet weak var indicatorView: CircularIndicatorView!
	@IBOutlet weak var spinnerView: SpinnerView!
	@IBOutlet weak var hintLabel: UILabel!
	@IBOutlet weak var indicatorLabel: UILabel!
	
	@IBOutlet weak var indicatorTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var hintLabelTopConstraint: NSLayoutConstraint!
	
	private(set) var state: State = .howToScan
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setState(.howToScan, animated: false)
		indicatorLabel.textColor = .tngBlue
		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissController)))
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		indicatorView.didAppear()
		
		let height = UIScreen.main.bounds.height
		let coeff: CGFloat = height > 667 ? 6.0 : 14.0
		let topOffset = height / coeff
		indicatorTopConstraint.constant = topOffset
		hintLabelTopConstraint.constant = topOffset / 3
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		setState(.idle, animated: false)
	}
	
	func setState(_ state: State, animated: Bool) {
		guard
			let howToScan = howToScanView,
			let indicator = indicatorView,
			let spinner = spinnerView
		else {
			self.state = .idle
			return
		}
		
		if self.state == state { return }
		
		var spinnerTargetAlpha: CGFloat = 0
		var howToScanTargetAlpha: CGFloat = 0
		var indicatorTargetAlpha: CGFloat = 0
		var hintText: String = ""
		self.state = state
		
		switch state {
		case .howToScan:
			howToScanTargetAlpha = 1
			howToScan.stopAnimation()
		case .percentProgress, .securityDelay:
			indicatorTargetAlpha = 1
		case .spinner:
			hintText = Localization.nfcAlertDefault
			spinnerTargetAlpha = 1
		case .idle:
			spinner.stopAnimation()
			howToScan.stopAnimation()
		}
		
		state == .spinner ? spinner.startAnimation() : spinner.stopAnimation()
		hintLabel.text = hintText
		
		UIView.animate(withDuration: animated ? 0.3 : 0.0, animations: {
			howToScan.alpha = howToScanTargetAlpha
			indicator.alpha = indicatorTargetAlpha
			spinner.alpha = spinnerTargetAlpha
		}, completion: { _ in
			state == .howToScan ? howToScan.startAnimation() : howToScan.stopAnimation()
		})
	}
	
	func setupIndicatorTotal(_ value: Float) {
		indicatorView.totalValue = value
	}
	
	@objc private func dismissController() {
		dismiss(animated: true, completion: nil)
	}
	
	public func tickSD(remainingValue: Float, message: String, hint: String? = nil) {
		indicatorView.tickSD(remainingValue: remainingValue)
		hintLabel.text = hint
		indicatorLabel.text = message
	}
	
	
	public func tickPercent(percentValue: Int, message: String, hint: String? = nil) {
		indicatorView.tickPercent(percentValue: percentValue)
		indicatorLabel.text = message
		hintLabel.text = hint
		indicatorView.currentPercentValue = percentValue
	}
	
}
