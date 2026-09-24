//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The header view of the suggestion collection view.
open class ChatSuggestionsHeaderView: _View, AppearanceProvider {
    /// The image icon of the commands header view.
    open private(set) lazy var commandImageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    /// The text label of the commands header view.
    open private(set) lazy var headerLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = appearance.colorPalette.backgroundCoreElevation1

        headerLabel.font = appearance.fonts.body
        headerLabel.textColor = appearance.colorPalette.textSecondary
        commandImageView.contentMode = .scaleAspectFit
    }

    override open func setUpLayout() {
        directionalLayoutMargins = .streamDefaultLayoutMargins

        // The content follows the margins rather than the value they have while this runs, which is
        // read once and goes stale as soon as the margins change, as they do on an orientation
        // change.
        let view = UIView().withoutAutoresizingMaskConstraints
        addSubview(view)
        view.pin(to: layoutMarginsGuide)

        view.addSubview(commandImageView)
        view.addSubview(headerLabel)
        commandImageView.pin(anchors: [.leading], to: view)
        commandImageView.pin(anchors: [.centerY], to: view)

        NSLayoutConstraint.activate(
            [
                commandImageView.centerYAnchor.pin(equalTo: headerLabel.centerYAnchor),
                headerLabel.centerYAnchor.pin(equalTo: commandImageView.centerYAnchor),
                headerLabel.leadingAnchor.pin(
                    equalToSystemSpacingAfter: commandImageView.trailingAnchor,
                    multiplier: 2
                )
            ]
        )
    }
}
