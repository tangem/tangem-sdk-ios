//
//  ScanCardAnimatedView.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/31/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit

@available (iOS 13.0, *)
class ScanCardAnimatedView: UIView {
	
	enum AnimType: String {
		case handAppear, handDisappear, pulse, checkmark
	}
	
	var isAnimating: Bool {
		handImageView.isAnimating
	}
	
	private let photoImage: UIImage? = UIImage(named: "phone", in: .sdkBundle, with: .none)
	private let handImage: UIImage? = UIImage(named: "hand", in: .sdkBundle, with: .none)
	
	private let phoneOffset = CGPoint(x: 8, y: 34)
	private let handEndOffset = CGPoint(x: -38, y: 0)
	private let handStartOffset = CGPoint(x: -278, y: 0)
	private let topOffset: CGFloat = 20
	private let hiddenHandScale: CGFloat = 0.5
	private let hiddenHandOpacity: CGFloat = 0.0
	private let displayedHandOpacity: CGFloat = 1.0
	
	private lazy var phoneImageView: UIImageView = {
		let view = UIImageView(image: photoImage)
		view.sizeToFit()
		return view
	}()
	private lazy var handImageView: UIImageView = {
		let view = UIImageView(image: handImage)
		view.sizeToFit()
		handDefaultSize = handImage?.size ?? view.bounds.size
		handHiddenSize = handDefaultSize * hiddenHandScale
		return view
	}()
	private lazy var pulseView: UIView = {
		let view = UIView(frame: CGRect(origin: phoneImageView.frame.origin,
										size: CGSize(width: phoneImageView.bounds.width, height: 20)))
		view.clipsToBounds = false
		return view
	}()
	private lazy var hiddenHandTransform: CATransform3D = { CATransform3DMakeScale(hiddenHandScale, hiddenHandScale, 1) }()
	
	private var phonePosition: CGPoint {
		handEndPos + CGPoint(x: handDefaultSize.width - phoneOffset.x - phoneImageView.bounds.size.width,
							 y: phoneOffset.y)
	}
	private var isNeedLayoutUpdate: Bool {
		phonePosition != phoneImageView.frame.origin
	}
	
	private let pulseLayerName = "pulse_layer"
	private let checkLayerName = "check_layer"
	private let checkmarkCircleLayerName = "checkmark_circle_layer"
	private let checkmarkLayerName = "checkmark_layer"
	private let animTypeKey = "anim_type"
	private let moveAnimKey = "movingHandAnim"
	private let pulseAnimKey = "pulseAnim"
	private let iosBlueColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
	
	private var handDefaultSize: CGSize = .zero
	private var handHiddenSize: CGSize = .zero
	private var handStartPos: CGPoint = .zero
	private var handEndPos: CGPoint = .zero
	private var handAppearAnim: CAAnimationGroup?
	private var handDisappearAnim: CAAnimationGroup?
	private var pulseAnim: CAAnimationGroup?
	private var firstPulseWave: CAShapeLayer?
	private var secondPulseWave: CAShapeLayer?
	private var checkmarkLayer: CAShapeLayer?
	
	init() {
		super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 250))
		layoutItems()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		layoutItems()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		guard isNeedLayoutUpdate else { return }
		layoutItems()
		handAppearAnim = nil
		handDisappearAnim = nil
		calculatePositions()
		layoutPhone()
		layoutHand()
		layoutPulse()
	}
	
	func startAnimation() {
		if handAppearAnim == nil {
			fireAppearAnim()
		}
		handImageView.layer.add(handAppearAnim!, forKey: moveAnimKey)
	}
	
	func startPulseAnim() {
		firePulseAnim()
	}
	
	func stopAnimation() {
		handImageView.layer.removeAllAnimations()
		checkmarkLayer?.sublayers?.forEach { $0.removeAllAnimations() }
		layoutHand()
	}
	
	// MARK: Layout
	
	private func layoutPulse() {
		if pulseView.superview == nil {
			insertSubview(pulseView, aboveSubview: handImageView)
		}
		if pulseView.layer.sublayers?.contains(where: { $0.name == pulseLayerName }) ?? false {
			return
		}
		
		guard firstPulseWave == nil, secondPulseWave == nil else { return }
		
		let pulseLayer = CAShapeLayer()
		pulseLayer.name = pulseLayerName
		let pulseR: CGFloat = 30
		let pulseD = pulseR * 2
		let waveWidth: CGFloat = 1.4
		let waveCenter = CGPoint(x: pulseView.bounds.width / 2, y: pulseR)
		let firstWave = wave(withDiameter: pulseD, color: iosBlueColor, lineWidth: waveWidth)
		firstWave.position = waveCenter
		let secondWave = wave(withDiameter: pulseD, color: iosBlueColor, lineWidth: waveWidth)
		secondWave.position = waveCenter
		pulseLayer.addSublayer(firstWave)
		pulseLayer.addSublayer(secondWave)
		firstPulseWave = firstWave
		secondPulseWave = secondWave
		pulseView.layer.addSublayer(pulseLayer)
	}
	
	private func layoutItems() {
		phoneImageView.sizeToFit()
		handImageView.sizeToFit()
		addSubview(handImageView)
		addSubview(phoneImageView)
	}
	
	private func calculatePositions() {
		handEndPos = handEndOffset +^ topOffset
		handStartPos = handStartOffset +^ topOffset + handHiddenSize.height / 2
	}
	
	private func layoutPhone() {
		phoneImageView.frame.origin = phonePosition
		
		let circleSize = CGSize(width: 45, height: 45)
		func checkmarkPos() -> CGPoint {
			let halfSize = circleSize / 2
			let phoneSize = phoneImageView.bounds.size
			let bottomOffset = (phoneSize * 0.2).height
			return CGPoint(x: phoneSize.width / 2,
						   y: phoneSize.height - bottomOffset - halfSize.height)
		}
		
		func addCheckmarkToPhone(_ checkLayer: CAShapeLayer) {
			phoneImageView.layer.addSublayer(checkLayer)
		}
		
		if let checkmark = checkmarkLayer {
			checkmark.position = checkmarkPos()
			if checkmark.superlayer == nil {
				addCheckmarkToPhone(checkmark)
			}
		} else {
			let checkLayer = CAShapeLayer()
			checkLayer.name = checkLayerName
			checkLayer.bounds = CGRect(origin: .zero, size: circleSize)
			let circle = UIBezierPath(roundedRect: checkLayer.bounds, cornerRadius: circleSize.width / 2)
			let circleLayer = CAShapeLayer()
			circleLayer.name = checkmarkCircleLayerName
			circleLayer.path = circle.cgPath
			circleLayer.fillColor = UIColor.clear.cgColor
			circleLayer.strokeColor = iosBlueColor.cgColor
			circleLayer.lineWidth = 2
			circleLayer.opacity = 0
			checkLayer.addSublayer(circleLayer)
			let checkmark = UIBezierPath()
			checkmark.move(to: CGPoint(x: 14, y: 24))
			checkmark.addLine(to: CGPoint(x: 20, y: 31))
			checkmark.addLine(to: CGPoint(x: 30, y: 15))
			let checkmarkLayer = CAShapeLayer()
			checkmarkLayer.name = checkmarkLayerName
			checkmarkLayer.path = checkmark.cgPath
			checkmarkLayer.fillColor = UIColor.clear.cgColor
			checkmarkLayer.strokeColor = iosBlueColor.cgColor
			checkmarkLayer.lineCap = .round
			checkmarkLayer.lineJoin = .round
			checkmarkLayer.lineWidth = 3
			checkmarkLayer.strokeEnd = 0
			checkLayer.addSublayer(checkmarkLayer)
			checkLayer.position = checkmarkPos()
			self.checkmarkLayer = checkLayer
			addCheckmarkToPhone(checkLayer)
		}
	}
	
	private func layoutHand() {
		handImageView.frame.origin = handStartPos
		handImageView.layer.transform = hiddenHandTransform
		handImageView.layer.opacity = 0
	}
	
	private func wave(withDiameter d: CGFloat, color: UIColor, lineWidth: CGFloat) -> CAShapeLayer {
		let wavePath = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: -d / 2, y: -d / 2), size: CGSize(width: d, height: d)))
		let wave = CAShapeLayer()
		wave.path = wavePath.cgPath
		wave.fillColor = nil
		wave.strokeColor = color.cgColor
		wave.lineWidth = lineWidth
		wave.opacity = 0
		return wave
	}
	
	// MARK: - Firing animations
	
	private func fireAppearAnim() {
		handImageView.layer.removeAllAnimations()
		let points = handAnimPoints()
		let group: CAAnimationGroup
		if let anim = handAppearAnim {
			group = anim
		} else {
			group = movementAnim(startPoint: points.start, endPoint: points.end, reversed: false)
			handAppearAnim = group
			
		}
		
		handImageView.layer.position = points.start
		handImageView.layer.opacity = 0
		handImageView.layer.transform = hiddenHandTransform
		handImageView.layer.add(group, forKey: moveAnimKey)
	}
	
	private func fireDisappearAnim() {
		handImageView.layer.removeAllAnimations()
		let points = handAnimPoints()
		let group: CAAnimationGroup
		if let anim = handDisappearAnim {
			group = anim
		} else {
			group = movementAnim(startPoint: points.start, endPoint: points.end, reversed: true)
			handDisappearAnim = group
		}
		
		handImageView.layer.position = points.end
		handImageView.layer.opacity = 1
		handImageView.layer.transform = CATransform3DIdentity
		handImageView.layer.add(group, forKey: moveAnimKey)
	}
	
	private func firePulseAnim() {
		firstPulseWave?.removeAllAnimations()
		secondPulseWave?.removeAllAnimations()
		firstPulseWave?.add(createPulseAnim(delay: 0, withDelegate: false), forKey: "pulse_anim")
		let anim = createPulseAnim(delay: 0.3, withDelegate: true)
		pulseAnim = anim
		secondPulseWave?.add(anim, forKey: "pulse_anim")
	}
	
	private func fireCheckmarkAnim(isDisappearing: Bool) {
		guard
			let checklayer = phoneImageView.layer.sublayer(with: checkLayerName),
			let circleLayer = checklayer.sublayer(with: checkmarkCircleLayerName),
			let checkmarkLayer = checklayer.sublayer(with: checkmarkLayerName) as? CAShapeLayer
		else { return }
		circleLayer.removeAllAnimations()
		checkmarkLayer.removeAllAnimations()
		let opacityAnim = CAKeyframeAnimation(keyPath: AnimKeyPaths.opacity, values: [0, 1], keyTimes: [0, 1], reversed: isDisappearing, duration: 0.3)
		let checkmarkAnim = CAKeyframeAnimation(keyPath: AnimKeyPaths.strokeEnd, values: [-1, 1], keyTimes: [0, 1], reversed: isDisappearing, duration: 0.3)
		if !isDisappearing {
			checkmarkAnim.setValue(AnimType.checkmark, forKey: animTypeKey)
			checkmarkAnim.delegate = self
		}
		circleLayer.add(opacityAnim, forKey: "opacity_anim")
		checkmarkLayer.add(checkmarkAnim, forKey: "checkmark_anim")
	}
	
	// MARK: - Animation calculations and setup
	
	private func handAnimPoints() -> (start: CGPoint, end: CGPoint) {
		let handHalfSize = handDefaultSize / 2
		let endPoint = handEndPos + handHalfSize
		let startPoint = handStartPos + handHalfSize
		return (start: startPoint, end: endPoint)
	}
	
	private func movementAnim(startPoint: CGPoint, endPoint: CGPoint, reversed: Bool) -> CAAnimationGroup {
		let opacityAnim = CAKeyframeAnimation(keyPath: AnimKeyPaths.opacity)
		opacityAnim.values = reversed ? [1, 0] : [0, 1]
		opacityAnim.keyTimes = [0, 1]
		opacityAnim.duration = 1.5
		opacityAnim.fillMode = .forwards
		opacityAnim.timingFunction = .init(controlPoints: 0.5, 0.2, 0.8, 0.35)
		opacityAnim.isRemovedOnCompletion = false
		
		let scaleAnim = CAKeyframeAnimation(keyPath: AnimKeyPaths.transScale)
		scaleAnim.values = reversed ? [CATransform3DIdentity, hiddenHandTransform] : [hiddenHandTransform, CATransform3DIdentity]
		scaleAnim.beginTime = reversed ? 0 : 0.3
		scaleAnim.duration = 1.2
		scaleAnim.fillMode = .forwards
		scaleAnim.timingFunction = .init(name: .easeInEaseOut)
		scaleAnim.isRemovedOnCompletion = false
		
		let pathAnim = CAKeyframeAnimation(keyPath: AnimKeyPaths.position)
		pathAnim.calculationMode = .paced
		pathAnim.duration = 1.5
		pathAnim.fillMode = .forwards
		pathAnim.isRemovedOnCompletion = false
		pathAnim.timingFunction = .init(name: .easeInEaseOut)
		
		let controlPoint = CGPoint(x: endPoint.x - 30, y: startPoint.y)
		let curvedPath = UIBezierPath()
		curvedPath.move(to: startPoint)
		curvedPath.addCurve(to: endPoint, controlPoint1: controlPoint, controlPoint2: controlPoint)
		let path = reversed ? curvedPath.reversing().cgPath : curvedPath.cgPath
		pathAnim.path = path
		
		let group = CAAnimationGroup()
		group.duration = 2.5
		group.fillMode = .forwards
		group.isRemovedOnCompletion = false
		group.delegate = self
		group.animations = [pathAnim, scaleAnim, opacityAnim]
		group.setValue(reversed ? AnimType.handDisappear : AnimType.handAppear, forKey: animTypeKey)
		
		return group
	}
	
	private func createPulseAnim(delay: Double, withDelegate: Bool) -> CAAnimationGroup {
		let opacity = CAKeyframeAnimation(keyPath: AnimKeyPaths.opacity,
										  values: [1, 0.8, 0.01, 0],
										  keyTimes: [0, 0.2, 0.9, 1],
										  reversed: false,
										  delay: delay)
		
		let scale = CAKeyframeAnimation(keyPath: AnimKeyPaths.transScale,
										values: [CATransform3DIdentity, CATransform3DMakeScale(3, 3, 1)],
										keyTimes: [0, 1],
										reversed: false,
										isRemovedOnCompletion: true,
										delay: delay)
		
		let group = CAAnimationGroup()
		group.duration = 1 + delay * 2
		group.fillMode = .forwards
		group.isRemovedOnCompletion = true
		group.timingFunction = .init(name: .linear)
		if withDelegate {
			group.delegate = self
			group.setValue(AnimType.pulse, forKey: animTypeKey)
		}
		
		group.animations = [opacity, scale]
		return group
	}
	
}

@available(iOS 13.0, *)
extension ScanCardAnimatedView: CAAnimationDelegate {
	func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
		guard
			flag,
			let type = anim.value(forKey: animTypeKey) as? AnimType
		else { return }
		let action: () -> Void
		let delay: TimeInterval
		switch type {
		case .handAppear:
			action = { self.firePulseAnim() }
			delay = 0
		case .pulse:
			action = { self.fireCheckmarkAnim(isDisappearing: false) }
			delay = 0.5
		case .handDisappear:
			action = { self.fireAppearAnim() }
			delay = 1
		case .checkmark:
			action = {
				self.fireCheckmarkAnim(isDisappearing: true)
				self.fireDisappearAnim()
			}
			delay = 1
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: action)
	}
}
