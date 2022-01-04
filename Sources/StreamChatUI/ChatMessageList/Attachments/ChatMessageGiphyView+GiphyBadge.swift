//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

extension ChatMessageGiphyView {
    open class GiphyBadge: _View, AppearanceProvider {
        public private(set) lazy var title: UILabel = {
            let label = UILabel().withoutAutoresizingMaskConstraints
            label.text = "GIPHY"
            label.textColor = appearance.colorPalette.staticColorText
            label.font = appearance.fonts.bodyBold
            return label.withBidirectionalLanguagesSupport
        }()

        public private(set) lazy var lightning = UIImageView(
            image: appearance
                .images
                .commandGiphy
        )
        public private(set) lazy var contentStack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [lightning, title]).withoutAutoresizingMaskConstraints
            stack.axis = .horizontal
            stack.alignment = .center
            return stack
        }()

        override open func setUpLayout() {
            super.setUpLayout()

            directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6)

            addSubview(contentStack)
            contentStack.pin(to: layoutMarginsGuide)
        }

        override open func setUpAppearance() {
            super.setUpAppearance()
            backgroundColor = UIColor.black.withAlphaComponent(0.6)
            lightning.tintColor = appearance.colorPalette.staticColorText
        }

        override open func layoutSubviews() {
            super.layoutSubviews()

            layer.cornerRadius = bounds.height / 2
        }
    }
}
