//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view that displays a poll in the message list.
open class PollAttachmentView: _View, ThemeProvider {
    /// The content data of the poll attachment view.
    public struct Content {
        public var poll: Poll

        public init(poll: Poll) {
            self.poll = poll
        }
    }

    /// The object responsible to
    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// A closure that is triggered whenever the option is tapped either from the button or the item itself.
    public var onOptionTap: ((PollOption) -> Void)?

    // MARK: - UI Components

    /// A label which by default displays the title of the Poll.
    open private(set) lazy var pollTitleLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withAccessibilityIdentifier(identifier: "pollTitleLabel")

    /// A label which by default displays the selection rules of the Poll.
    open private(set) lazy var pollSubtitleLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withAccessibilityIdentifier(identifier: "pollSubtitleLabel")

    /// A label which by default displays the selection rules of the Poll.
    open private(set) lazy var optionListView: PollAttachmentOptionListView = components
        .pollAttachmentOptionListView.init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "optionsListView")

    // MARK: - Lifecycle

    override open func setUpAppearance() {
        super.setUpAppearance()

        clipsToBounds = true
        pollTitleLabel.font = appearance.fonts.subheadlineBold
        pollTitleLabel.numberOfLines = 0
        pollSubtitleLabel.font = appearance.fonts.caption1
        pollSubtitleLabel.textColor = appearance.colorPalette.textLowEmphasis
    }

    override open func setUpLayout() {
        super.setUpLayout()

        directionalLayoutMargins = .init(top: 12, leading: 10, bottom: 12, trailing: 12)

        VContainer(spacing: 14) {
            VContainer(spacing: 2) {
                pollTitleLabel
                pollSubtitleLabel
            }
            optionListView
        }
        .embedToMargins(in: self)
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else {
            return
        }

        pollTitleLabel.text = content.poll.name
        pollSubtitleLabel.text = "Select one or more"
        optionListView.onOptionTap = onOptionTap
        optionListView.content = .init(poll: content.poll)
    }
}
