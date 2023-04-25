//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

open class SlideToCancelView: _View, ThemeProvider {
    var content: String = L10n.Recording.slideToCancel {
        didSet { updateContentIfNeeded() }
    }

    open lazy var container: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var titleLabel: UILabel = .init()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport

    open lazy var chevronImageView: UIImageView = .init()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()

        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(chevronImageView)
        chevronImageView.contentMode = .center

        container.axis = .horizontal
        container.spacing = 8

        addSubview(container)
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            container.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        chevronImageView.image = appearance.images.chevronLeft.tinted(with: appearance.colorPalette.textLowEmphasis)
        titleLabel.textColor = appearance.colorPalette.textLowEmphasis
        titleLabel.font = appearance.fonts.body
    }

    override open func updateContent() {
        super.updateContent()
        titleLabel.text = content
    }
}
