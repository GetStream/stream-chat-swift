//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view that displays a poll option in the poll option list view.
open class PollAttachmentOptionListItemView: _View, ThemeProvider {
    public struct Content {
        public var option: PollOption
    }

    public var content: Content

    public required init(content: Content) {
        self.content = content
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Components

    /// A label which displays the name of the option.
    open private(set) lazy var optionNameLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withAccessibilityIdentifier(identifier: "optionNameLabel")

    /// A label which displays the number of votes of the option.
    open private(set) lazy var votesCountLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withAccessibilityIdentifier(identifier: "votesCountLabel")

    // MARK: - Lifecycle

    override open func setUpAppearance() {
        super.setUpAppearance()

        optionNameLabel.numberOfLines = 0
        optionNameLabel.font = appearance.fonts.subheadline
        votesCountLabel.font = appearance.fonts.caption1
        votesCountLabel.textColor = appearance.colorPalette.textLowEmphasis
    }

    override open func setUpLayout() {
        super.setUpLayout()

        VContainer(spacing: 2) {
            HContainer {
                optionNameLabel
                Spacer()
                votesCountLabel
            }
        }
        .embed(in: self)
    }

    override open func updateContent() {
        super.updateContent()

        optionNameLabel.text = content.option.text
        votesCountLabel.text = "\(content.option.latestVotes.count)"
    }
}
