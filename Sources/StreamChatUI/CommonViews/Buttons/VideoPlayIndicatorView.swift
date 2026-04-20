//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

/// A circular button that displays a play icon on top of video attachment previews.
///
/// Uses `controlPlayButtonBackground` and `controlPlayButtonIcon` color tokens.
class VideoPlayIndicatorView: _Button, AppearanceProvider {
    private static let containerSize: CGFloat = 48
    private static let iconSize: CGFloat = 20

    private(set) lazy var iconImageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    // MARK: - UI Lifecycle

    override func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = appearance.colorPalette.controlPlayButtonBackground
        clipsToBounds = true

        let icon = appearance.images.bigPlay.withRenderingMode(.alwaysTemplate)
        iconImageView.image = icon
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = appearance.colorPalette.controlPlayButtonIcon
    }

    override func setUpLayout() {
        super.setUpLayout()

        pin(anchors: [.width, .height], to: Self.containerSize)

        addSubview(iconImageView)
        iconImageView.pin(anchors: [.centerX, .centerY], to: self)
        iconImageView.pin(anchors: [.width, .height], to: Self.iconSize)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}
