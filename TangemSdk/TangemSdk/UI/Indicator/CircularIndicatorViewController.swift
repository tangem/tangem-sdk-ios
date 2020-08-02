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
}

class CircularIndicatorViewController: UIViewController {    
    @IBOutlet weak var lbltext: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var lblHint: UILabel!
    @IBOutlet weak var lblHintTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerTopConstraint: NSLayoutConstraint!
    
    var totalValue: Float = 0
    var isClockwise: Bool = false
    var mode: IndicatorMode = .sd
    private let shapeLayer = CAShapeLayer()
    private let trackLayer = CAShapeLayer()
    private var currentPercentValue: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
         setupUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        lbltext.text = ""
        lblHint.text = ""
        currentPercentValue = 0
        shapeLayer.removeAllAnimations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
}
