//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatLoadingIndicator = _ChatLoadingIndicator<NoExtraData>

open class _ChatLoadingIndicator<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    override open var isHidden: Bool {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    public private(set) lazy var imageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    // MARK: - Overrides

    override public func defaultAppearance() {
        imageView.image = uiConfig.loadingIndicator.image
    }

    override open func setUpLayout() {
        embed(imageView)
        widthAnchor.pin(equalTo: heightAnchor).isActive = true
    }

    override open func updateContent() {
        isHidden ? stopRotating() : startRotation()
    }
}

// MARK: - Private

private extension _ChatLoadingIndicator {
    static var kRotationAnimationKey: String { "rotationanimationkey" }

    func startRotation() {
        guard layer.animation(forKey: Self.kRotationAnimationKey) == nil else { return }

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0.0
        rotationAnimation.toValue = Float.pi * 2.0
        rotationAnimation.duration = uiConfig.loadingIndicator.rotationPeriod
        rotationAnimation.repeatCount = Float.infinity

        layer.add(rotationAnimation, forKey: Self.kRotationAnimationKey)
    }

    func stopRotating() {
        layer.removeAnimation(forKey: Self.kRotationAnimationKey)
    }
}
