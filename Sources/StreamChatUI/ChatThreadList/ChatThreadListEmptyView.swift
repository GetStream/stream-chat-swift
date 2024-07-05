//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// The view shown when the thread list is empty.
open class ChatThreadListEmptyView: _View, ThemeProvider {
    /// The stack view that holds the icon and description view.
    open private(set) lazy var container = UIStackView()
        .withoutAutoresizingMaskConstraints
    /// The icon view that shows the thread icon.
    open private(set) lazy var iconView = UIImageView()
        .withoutAutoresizingMaskConstraints
    /// The description view that says that there are no threads fetched.
    open private(set) lazy var descriptionLabel = UILabel()
        .withoutAutoresizingMaskConstraints

    override open func setUp() {
        super.setUp()

        descriptionLabel.text = L10n.ThreadList.Empty.description
    }

    override open func setUpLayout() {
        super.setUpLayout()

        directionalLayoutMargins = .init(top: 8, leading: 32, bottom: 8, trailing: 32)

        addSubview(container)
        container.pin(anchors: [.centerX, .centerY], to: self)
        container.pin(anchors: [.leading, .trailing], to: layoutMarginsGuide)
        container.axis = .vertical
        container.alignment = .center
        container.addArrangedSubview(iconView)
        container.addArrangedSubview(descriptionLabel)
        container.spacing = 12

        NSLayoutConstraint.activate([
            iconView.widthAnchor.pin(equalToConstant: 130),
            iconView.heightAnchor.pin(equalToConstant: 130)
        ])
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = appearance.colorPalette.background

        iconView.image = appearance.images.threadIcon
        iconView.tintColor = appearance.colorPalette.alternativeInactiveTint

        descriptionLabel.font = appearance.fonts.subheadline
        descriptionLabel.textColor = appearance.colorPalette.subtitleText
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
    }
}
