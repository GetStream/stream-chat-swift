//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatLoadingIndicator: _View, AppearanceProvider {
    override open var isHidden: Bool {
        didSet { updateContentIfNeeded() }
    }

    open var rotationPeriod: TimeInterval = 1

    // MARK: - Subviews

    public private(set) lazy var imageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    // MARK: - Overrides

    override open func setUpAppearance() {
        super.setUpAppearance()
        imageView.image = appearance.images.loadingIndicator
    }

    override open func setUpLayout() {
        embed(imageView)
        widthAnchor.pin(equalTo: heightAnchor).isActive = true
    }

    override open func updateContent() {
        isHidden ? stopRotating() : startRotation()
    }

    static var kRotationAnimationKey: String { "rotationanimationkey" }

    open func startRotation() {
        guard layer.animation(forKey: Self.kRotationAnimationKey) == nil else { return }

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0.0
        rotationAnimation.toValue = Float.pi * 2.0
        rotationAnimation.duration = rotationPeriod
        rotationAnimation.repeatCount = Float.infinity

        layer.add(rotationAnimation, forKey: Self.kRotationAnimationKey)
    }

    open func stopRotating() {
        layer.removeAnimation(forKey: Self.kRotationAnimationKey)
    }
}
