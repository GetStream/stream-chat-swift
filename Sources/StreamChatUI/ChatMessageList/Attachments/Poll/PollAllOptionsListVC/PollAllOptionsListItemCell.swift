//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The `UITableViewCell` for the poll `PollAllOptionsListVC`.
open class PollAllOptionsListItemCell: _TableViewCell, ThemeProvider {
    public struct Content {
        public var option: PollOption
        public var poll: Poll

        public init(option: PollOption, poll: Poll) {
            self.option = option
            self.poll = poll
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// A button to add or remove a vote for this option.
    open private(set) lazy var voteCheckboxButton = CheckboxButton(type: .roundedRect)
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "voteCheckboxView")

    /// A label which displays the name of the option.
    open private(set) lazy var optionNameLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "optionNameLabel")

    /// A label which displays the number of votes of the option.
    open private(set) lazy var votesCountLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "votesCountLabel")

    override open func setUpAppearance() {
        super.setUpAppearance()

        selectionStyle = .none
        backgroundColor = appearance.colorPalette.background1
        optionNameLabel.numberOfLines = 0
        optionNameLabel.font = appearance.fonts.subheadline
        votesCountLabel.font = appearance.fonts.body
        votesCountLabel.textColor = appearance.colorPalette.text
        voteCheckboxButton.contentEdgeInsets = .zero
        voteCheckboxButton.imageEdgeInsets = .zero
        voteCheckboxButton.titleEdgeInsets = .zero
    }

    override open func setUpLayout() {
        super.setUpLayout()

        HContainer(spacing: 12) {
            voteCheckboxButton
            optionNameLabel.flexible(axis: .horizontal)
            votesCountLabel
        }.embed(in: self, insets: .init(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    override open func updateContent() {
        guard let content = self.content else { return }

        let option = content.option
        let poll = content.poll
        optionNameLabel.text = option.text
        votesCountLabel.text = "\(poll.voteCount(for: option))"

        if poll.hasCurrentUserVoted(for: option) {
            voteCheckboxButton.setCheckedState()
        } else {
            voteCheckboxButton.setUncheckedState()
        }
        voteCheckboxButton.isHidden = poll.isClosed
    }
}
