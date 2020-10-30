//
//  ScanViewController.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 06.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class ScanViewController: UIViewController {
    var cardSession: CardSession?
    var cancelledHandler: (() -> Void)?
	private static let handLeadingFrom: CGFloat = -50.0
	private var handLeadingTo: CGFloat = 0.0 //calculate later
    
    @IBOutlet weak var hintLabel: UILabel!
    @IBOutlet weak var buttonTapIn: UIButton! {
        didSet {
            buttonTapIn.layer.cornerRadius = 8.0
        }
    }
    @IBOutlet weak var imageHandLeading: NSLayoutConstraint!
    @IBOutlet weak var imageHand: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var buttonCancel: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let offset = view.frame.width/2.0 - imageHand.frame.width/2.0 - 30.0
        handLeadingTo = ScanViewController.handLeadingFrom + offset
		imageHand.alpha = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimation()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        view.layer.removeAllAnimations()
    }
    
    func startAnimation() {
		UIView.animateKeyframes(withDuration: 5.0, delay: 0.2, options: [.repeat, .calculationModeLinear], animations: {
            
			UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.1) {
				self.imageHand.alpha = 1
			}
			
            UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.3) {
                self.imageHandLeading.constant = self.handLeadingTo
                self.view.layoutIfNeeded()
            }
            
			UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.4) {}
			
            UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.1) {
                self.imageHand.alpha = 0.0
            }
			
			UIView.addKeyframe(withRelativeStartTime: 0.9, relativeDuration: 0.1, animations: {})
            
        }) { completed in
            self.imageHandLeading.constant = ScanViewController.handLeadingFrom
        }
    }
	
	func dismissController(animated: Bool, completion: (() -> Void)?) {
		dismiss(animated: animated, completion: completion)
		postDismissSetup()
	}
	
	func postDismissSetup() {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			self.imageHandLeading.constant = ScanViewController.handLeadingFrom
		}
	}
    
    @IBAction func buttonCancelTapped(_ sender: Any) {
        self.cancelledHandler?()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func buttonTapInTapped(_ sender: Any) {
        cardSession?.start()
    }
    
    init?(coder: NSCoder, session: CardSession, cancelledHandler: @escaping () -> Void) {
        self.cardSession = session
        self.cancelledHandler = cancelledHandler
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
		super.init(coder: coder)
//        fatalError("init(coder:) has not been implemented")
    }
    
}
