//
//  ReadCardAnimationModifier.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

struct ReadCardAnimationModifier: AnimatableModifier {
    var progress: Double // from 0 to 1
    let cardWidth: CGFloat
    let verticalOffset: CGFloat

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .offset(x: offsetX(geometry: geometry), y: verticalOffset)
        }
    }

    private func offsetX(geometry: GeometryProxy) -> CGFloat {
        let width = geometry.size.width
        let startX = -cardWidth
        let centerX = (width - cardWidth) / 2

        let toCenter = Double(progress).interpolatedProgress(inRange: 0.12...0.24)
        let toLeft = Double(progress).interpolatedProgress(inRange: 0.88...1.00)

        if progress < 0.12 {
            return startX
        } else if progress < 0.24 {
            return startX + (centerX - startX) * toCenter
        } else if progress < 0.88 {
            return centerX
        } else {
            return centerX + (startX - centerX) * toLeft
        }
    }
}

extension View {
    func discreteAnimation(progress: Double, cardWidth: CGFloat, verticalOffset: CGFloat = 0) -> some View {
        self.modifier(ReadCardAnimationModifier(progress: progress, cardWidth: cardWidth, verticalOffset: verticalOffset))
    }
}

fileprivate extension BinaryFloatingPoint {
    /// Interpolates the value of the receiver to a fractional progress within the given range:
    ///    - `range.lowerBound` corresponds to a progress of 0.0
    ///    - `range.upperBound` corresponds to a progress of 1.0
    ///    - Values between `range.lowerBound` and `range.upperBound` are interpolated linearly
    func interpolatedProgress(inRange range: ClosedRange<Self>) -> Self {
        assert(self >= 0.0)
        assert(self <= 1.0)
        assert(range.lowerBound >= 0.0)
        assert(range.upperBound <= 1.0)

        if self <= range.lowerBound {
            return 0.0
        }

        if self < range.upperBound {
            let rangeLength = range.upperBound - range.lowerBound

            return (self - range.lowerBound) / rangeLength
        }

        return 1.0
    }
}
