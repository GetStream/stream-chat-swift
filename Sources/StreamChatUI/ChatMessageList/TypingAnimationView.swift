//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A `UIView` subclass with 3 dots which can be animated with fading out effect.
open class TypingAnimationView: _View, AppearanceProvider {
    open var dotSize: CGSize = .init(width: 5, height: 5)

    open var opacityFromValue: Double = 0.9
    open var opacityToValue: Double = 0.3
    open var opacityDuration: TimeInterval = 1
    open var numberOfDots: Int = 3
    open var dotSpacing: CGFloat = 2

    /// Defines the width of the view
    /// It is computed by multiplying the dotLayer width with spacing and number of dots.
    /// Also because we use the replicator layer, we mustn't forgot to remove the last spacing, otherwise it has trailing margin.
    public var viewWidthConstant: CGFloat {
        dotLayer.frame.size.width * dotSpacing * CGFloat(numberOfDots) - dotSize.width
    }

    open private(set) lazy var dotLayer: CALayer = {
        let layer = CALayer()
        layer.frame.size = dotSize
        layer.cornerRadius = dotSize.height / 2
        return layer
    }()

    open private(set) lazy var replicatorLayer = CAReplicatorLayer()

    override open func setUpLayout() {
        super.setUpLayout()
        widthAnchor.pin(equalToConstant: viewWidthConstant).isActive = true
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = .clear
        dotLayer.backgroundColor = appearance.colorPalette.text.cgColor
        replicatorLayer.frame = bounds
    }
        
    open func startAnimating() {
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = opacityFromValue
        opacityAnimation.toValue = opacityToValue
        opacityAnimation.duration = opacityDuration
        opacityAnimation.repeatCount = .infinity

        replicatorLayer.addSublayer(dotLayer)

        replicatorLayer.instanceCount = numberOfDots
        // Add spacing 1 times the dot between the dots as designed.
        replicatorLayer.instanceTransform = CATransform3DMakeTranslation((dotLayer.frame.size.width) * dotSpacing, 0, 0)

        replicatorLayer.instanceDelay = opacityAnimation.duration / Double(replicatorLayer.instanceCount)
        layer.addSublayer(replicatorLayer)

        dotLayer.add(opacityAnimation, forKey: "Typing indicator")
    }
}
