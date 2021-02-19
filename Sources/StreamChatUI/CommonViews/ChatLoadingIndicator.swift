//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatLoadingIndicator = _ChatLoadingIndicator<NoExtraData>

internal class _ChatLoadingIndicator<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    override internal var isHidden: Bool {
        didSet { updateContentIfNeeded() }
    }

    internal var rotationPeriod: TimeInterval = 1

    // MARK: - Subviews

    internal private(set) lazy var imageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    // MARK: - Overrides

    override internal func defaultAppearance() {
        imageView.image = uiConfig.images.loadingIndicator
    }

    override internal func setUpLayout() {
        embed(imageView)
        widthAnchor.pin(equalTo: heightAnchor).isActive = true
    }

    override internal func updateContent() {
        isHidden ? stopRotating() : startRotation()
    }

    static var kRotationAnimationKey: String { "rotationanimationkey" }

    internal func startRotation() {
        guard layer.animation(forKey: Self.kRotationAnimationKey) == nil else { return }

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0.0
        rotationAnimation.toValue = Float.pi * 2.0
        rotationAnimation.duration = rotationPeriod
        rotationAnimation.repeatCount = Float.infinity

        layer.add(rotationAnimation, forKey: Self.kRotationAnimationKey)
    }

    internal func stopRotating() {
        layer.removeAnimation(forKey: Self.kRotationAnimationKey)
    }
}
