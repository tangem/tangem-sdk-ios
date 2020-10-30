//
//  CircularIndicatorViewController.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 30.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit

public enum IndicatorMode {
    case sd
    case percent
	case spinner
}

class CircularIndicatorViewController: UIViewController {    
    @IBOutlet weak var lbltext: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var lblHint: UILabel!
    @IBOutlet weak var lblHintTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var spinner: UIImageView!
    
    var totalValue: Float = 0
    var isClockwise: Bool = false
    
    private let shapeLayer = CAShapeLayer()
    private let trackLayer = CAShapeLayer()
	
	private(set) var mode: IndicatorMode = .sd
	
	private var shouldAnimateSpinner: Bool = false
    private var currentPercentValue: Int = 0
	
	private var pendingMode: IndicatorMode?
	private var isSpinnerIdle = true
    
    override func viewDidLoad() {
		super.viewDidLoad()
		setupUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        lbltext.text = ""
		shouldAnimateSpinner = false
        currentPercentValue = 0
        shapeLayer.removeAllAnimations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		if let pendingMode = pendingMode {
			setMode(pendingMode, animated: false)
		}
        if isClockwise || mode == .percent {
            shapeLayer.strokeEnd = 0
        } else {
            shapeLayer.strokeEnd = CGFloat(1.0 - 1.0/totalValue)
        }
        
       let height = UIScreen.main.bounds.height
       let coeff: CGFloat = height > 667 ? 6.0 : 14.0
       let topOffset = height / coeff
       containerTopConstraint.constant = topOffset
       lblHintTopConstraint.constant = topOffset/3
		
		if mode == .spinner {
			shouldAnimateSpinner = true
			animateSpinner()
		}
    }
    
    func setupUI() {
        // let's start by drawing a circle somehow
        let center = CGPoint(x: containerView.bounds.maxX/2.0, y: containerView.bounds.maxY/2.0)
        // create my track layer
        
        let circularPath = UIBezierPath(arcCenter: center, radius: 92, startAngle: -CGFloat.pi / 2, endAngle: 1.5 * CGFloat.pi, clockwise: true)
        trackLayer.path = circularPath.cgPath
        trackLayer.strokeColor = UIColor(red: 215.0/255.0, green: 229.0/255.0, blue: 247.0/255.0, alpha: 1.0).cgColor
        trackLayer.lineWidth = 6
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = CAShapeLayerLineCap.round
        
        if trackLayer.superlayer == nil {
            containerView.layer.addSublayer(trackLayer)
        }
        
        shapeLayer.path = circularPath.cgPath
        shapeLayer.strokeColor = UIColor.tngBlue.cgColor
        shapeLayer.lineWidth = 6
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = CAShapeLayerLineCap.butt

        if shapeLayer.superlayer == nil {
            containerView.layer.addSublayer(shapeLayer)
        }
    }
	
	public func setMode(_ mode: IndicatorMode, animated: Bool) {
		guard
			let containerView = containerView,
			let spinner = spinner
		else {
			pendingMode = mode
			return
		}
		if pendingMode == nil, mode == self.mode { return }
		let spinnerTargetAlpha: CGFloat
		let containerTargetAlpha: CGFloat
		self.mode = mode
		pendingMode = nil
		switch mode {
		case .spinner:
			spinnerTargetAlpha = 1.0
			containerTargetAlpha = 0.0
			lblHint.text = Localization.nfcAlertDefault
			shouldAnimateSpinner = true
		default:
			spinnerTargetAlpha = 0.0
			containerTargetAlpha = 1.0
			shouldAnimateSpinner = false
		}
		animateSpinner()
		UIView.animate(withDuration: animated ? 0.3 : 0.0) {
			containerView.alpha = containerTargetAlpha
			spinner.alpha = spinnerTargetAlpha
		}
	}
    
    public func tickSD(remainingValue: Float, message: String, hint: String? = nil) {
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        if isClockwise {
            basicAnimation.fromValue = (totalValue - remainingValue)/totalValue
            basicAnimation.toValue = (totalValue - remainingValue+1.0)/totalValue
        } else {
            basicAnimation.fromValue = remainingValue/totalValue
            basicAnimation.toValue = (remainingValue-1.0)/totalValue
        }
        basicAnimation.duration = 0.9
        basicAnimation.fillMode = CAMediaTimingFillMode.forwards
        basicAnimation.isRemovedOnCompletion = false
        shapeLayer.add(basicAnimation, forKey: "urSoBasic")
        lbltext.text = message
        lblHint.text = hint
    }
    
    
    public func tickPercent(percentValue: Int, message: String, hint: String? = nil) {
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        basicAnimation.fromValue = Float(currentPercentValue)/100.0
        basicAnimation.toValue = Float(percentValue)/100.0
        basicAnimation.duration = 0.2
        basicAnimation.fillMode = CAMediaTimingFillMode.forwards
        basicAnimation.isRemovedOnCompletion = false
        shapeLayer.add(basicAnimation, forKey: "urSoBasic")
        lbltext.text = message
        lblHint.text = hint
        currentPercentValue = percentValue
    }
	
	private func animateSpinner() {
		guard shouldAnimateSpinner, isSpinnerIdle else { return }
		isSpinnerIdle = false
		UIView.animate(withDuration: 0.5, delay: 0, options: [.curveLinear], animations: {
			self.spinner.transform = self.spinner.transform.rotated(by: .pi * 0.9999)
		}, completion: { _ in
			self.isSpinnerIdle = true
			self.animateSpinner()
		})
	}
}
