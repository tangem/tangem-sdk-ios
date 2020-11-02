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
		case handAppear, handDisappear, pulse
	}
	
	struct AnimKeyPaths {
		static let transScale = "transform.scale"
		static let opacity = "opacity"
		static let position = "position"
	}
	
	var isAnimating: Bool {
		handImageView.isAnimating
	}
	
	private let photoImage: UIImage? = UIImage(named: "phone", in: .sdkBundle, with: .none)
	private let handImage: UIImage? = UIImage(named: "hand", in: .sdkBundle, with: .none)
	
	private let phoneOffset = CGPoint(x: 11, y: 35)
	private let handEndOffset = CGPoint(x: 40, y: 0)
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
	
	
	private var handDefaultSize: CGSize = .zero
	private var handHiddenSize: CGSize = .zero
	private var handStartPos: CGPoint = .zero
	private var handEndPos: CGPoint = .zero
	private var handAppearAnim: CAAnimationGroup?
	private var handDisappearAnim: CAAnimationGroup?
	private var pulseAnim: CAAnimationGroup?
	private var firstPulseWave: CAShapeLayer?
	private var secondPulseWave: CAShapeLayer?
	
	private let pulseLayerName = "pulse_layer"
	private let animTypeKey = "anim_type"
	private let moveAnimKey = "movingHandAnim"
	private let pulseAnimKey = "pulseAnim"
	private let pulseColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
	
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
		layoutHand()
	}
	
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
		let firstWave = wave(withDiameter: pulseD, color: pulseColor, lineWidth: waveWidth)
		firstWave.position = waveCenter
		let secondWave = wave(withDiameter: pulseD, color: pulseColor, lineWidth: waveWidth)
		secondWave.position = waveCenter
		pulseLayer.addSublayer(firstWave)
		pulseLayer.addSublayer(secondWave)
		firstPulseWave = firstWave
		secondPulseWave = secondWave
		pulseView.layer.addSublayer(pulseLayer)
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
	
	private func layoutItems() {
		phoneImageView.sizeToFit()
		handImageView.sizeToFit()
		addSubview(handImageView)
		addSubview(phoneImageView)
	}
	
	private func calculatePositions() {
		handEndPos = handEndOffset +^ topOffset
		handStartPos = CGPoint(x: -100, y: topOffset + handHiddenSize.height / 2)
	}
	
	private func layoutPhone() {
		phoneImageView.frame.origin = phonePosition
	}
	
	private func layoutHand() {
		handImageView.frame.origin = handStartPos
		handImageView.layer.transform = hiddenHandTransform
		handImageView.layer.opacity = 0
	}
	
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
		print("Anim curved path", path)
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
		let opacity = CAKeyframeAnimation(keyPath: AnimKeyPaths.opacity)
		opacity.values = [1, 0.8, 0.01, 0]
		opacity.keyTimes = [0, 0.2, 0.9, 1]
		opacity.fillMode = .forwards
		opacity.beginTime = delay
		opacity.isRemovedOnCompletion = false
		
		let scale = CAKeyframeAnimation(keyPath: AnimKeyPaths.transScale)
		scale.values = [CATransform3DIdentity, CATransform3DMakeScale(3, 3, 1)]
		scale.keyTimes = [0, 1]
		scale.fillMode = .forwards
		scale.beginTime = delay
		scale.isRemovedOnCompletion = true
		
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
			action = { self.fireDisappearAnim() }
			delay = 0.5
		case .handDisappear:
			action = { self.fireAppearAnim() }
			delay = 1
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: action)
	}
}
