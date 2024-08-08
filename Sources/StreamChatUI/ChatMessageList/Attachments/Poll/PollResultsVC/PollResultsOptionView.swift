//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The poll option view displayed in the section header of the poll results.
open class PollResultsOptionView: _View, ThemeProvider {
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

    /// The label that displays the option name.
    open private(set) lazy var optionNameLabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory

    open private(set) lazy var medalImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    /// The label that displays the number of votes in an option.
    open private(set) lazy var votesLabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = appearance.colorPalette.background1
        optionNameLabel.numberOfLines = 0
        optionNameLabel.font = appearance.fonts.headlineBold
        optionNameLabel.textColor = appearance.colorPalette.text
        votesLabel.font = appearance.fonts.body.withSize(17)
        votesLabel.textColor = appearance.colorPalette.text
        medalImageView.image = appearance.images.pollWinnerMedal
        medalImageView.tintColor = appearance.colorPalette.textLowEmphasis
    }

    override open func setUpLayout() {
        super.setUpLayout()

        directionalLayoutMargins = .init(top: 12, leading: 12, bottom: 12, trailing: 12)

        HContainer(spacing: 4, alignment: .center) {
            optionNameLabel
            Spacer()
            HContainer(spacing: 6) {
                medalImageView
                    .width(20)
                    .height(20)
                votesLabel.layout {
                    $0.setContentCompressionResistancePriority(.streamRequire, for: .horizontal)
                }
            }
        }.embedToMargins(in: self)
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else { return }

        optionNameLabel.text = content.option.text
        let voteCount = content.poll.voteCount(for: content.option)
        votesLabel.text = L10n.Message.Polls.votes(voteCount)
        medalImageView.isHidden = !content.poll.isOptionWinner(content.option)
    }
}
