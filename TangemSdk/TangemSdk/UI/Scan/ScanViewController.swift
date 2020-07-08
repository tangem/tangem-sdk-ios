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
    var cardSession: CardSession
    private static let handLeadingFrom = -50.0
    private var handLeadingTo = 0.0 //calculate later
    
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
        handLeadingTo = ScanViewController.handLeadingFrom + Double(offset)
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
        UIView.animateKeyframes(withDuration: 3.0, delay: 0.2, options: [.repeat, .calculationModeLinear], animations: {
            
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.6) {
                self.imageHandLeading.constant = CGFloat(self.handLeadingTo)
                self.view.layoutIfNeeded()
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.3) {
                self.imageHand.alpha = 0.0
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.9, relativeDuration: 0.1) {}
            
        }) { completed in
            self.imageHand.alpha = 1.0
            self.imageHandLeading.constant = CGFloat(ScanViewController.handLeadingFrom)
        }
    }
    
    @IBAction func buttonCancelTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func buttonTapInTapped(_ sender: Any) {
        cardSession.start()
    }
    
    init?(coder: NSCoder, session: CardSession) {
        self.cardSession = session
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
