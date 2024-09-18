//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The poll creation section header view.
open class PollCreationSectionHeaderView: _TableHeaderFooterView, ThemeProvider {
    public struct Content {
        public var title: String

        public init(title: String) {
            self.title = title
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The label that displays the section name.
    open private(set) lazy var titleLabel = UILabel()
        .withoutAutoresizingMaskConstraints

    override open func setUpAppearance() {
        super.setUpAppearance()

        titleLabel.numberOfLines = 1
        titleLabel.font = appearance.fonts.body
        titleLabel.textColor = appearance.colorPalette.text
    }

    override open func setUpLayout() {
        super.setUpLayout()

        HContainer(alignment: .leading) {
            titleLabel
        }.embed(in: self, insets: .init(top: 4, leading: 16, bottom: 4, trailing: 16))
    }

    override open func updateContent() {
        super.updateContent()

        titleLabel.text = content?.title
    }
}
