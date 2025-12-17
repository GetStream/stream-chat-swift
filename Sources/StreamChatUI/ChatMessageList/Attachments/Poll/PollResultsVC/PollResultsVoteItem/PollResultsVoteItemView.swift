//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatCommonUI
import UIKit

/// The vote item view that displays information in a poll results cell.
open class PollResultsVoteItemView: _View, ThemeProvider {
    public struct Content {
        public var vote: PollVote
        public var poll: Poll

        public init(vote: PollVote, poll: Poll) {
            self.vote = vote
            self.poll = poll
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The user avatar of the voter.
    open private(set) lazy var authorAvatarView: ChatUserAvatarView = components
        .userAvatarView.init()
        .withoutAutoresizingMaskConstraints

    /// The label that displays the author name.
    open private(set) lazy var authorNameLabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory

    /// The label that displays the timestamp of the vote.
    open private(set) lazy var voteTimestampLabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory

    override open func setUpAppearance() {
        super.setUpAppearance()

        authorAvatarView.shouldShowOnlineIndicator = false
        authorNameLabel.font = appearance.fonts.body
        authorNameLabel.textColor = appearance.colorPalette.text
        voteTimestampLabel.font = appearance.fonts.body.withSize(14)
        voteTimestampLabel.textColor = appearance.colorPalette.textLowEmphasis
    }

    override open func setUpLayout() {
        super.setUpLayout()

        directionalLayoutMargins = .init(top: 0, leading: 12, bottom: 0, trailing: 12)

        HContainer(spacing: 4, alignment: .center) {
            authorAvatarView
                .width(20)
                .height(20)
            authorNameLabel
            Spacer()
            voteTimestampLabel
        }
        .height(greaterThanOrEqualTo: 40)
        .embedToMargins(in: self)
    }

    override open func updateContent() {
        guard let content = self.content else { return }

        if content.poll.votingVisibility == .anonymous {
            authorAvatarView.isHidden = true
            authorNameLabel.text = L10n.Polls.anonymousAuthor
        } else {
            authorAvatarView.content = content.vote.user
            authorNameLabel.text = content.vote.user?.name
        }

        let formatter = appearance.formatters.pollVoteTimestamp
        let voteDay = formatter.formatDay(content.vote.createdAt)
        let voteTime = formatter.formatTime(content.vote.createdAt)
        let originalString = [voteDay, voteTime].joined(separator: " ")
        let attributedString = NSMutableAttributedString(string: originalString)
        if let range = originalString.range(of: voteDay) {
            let nsRange = NSRange(range, in: originalString)
            attributedString.addAttribute(.font, value: voteTimestampLabel.font.bold, range: nsRange)
        }
        voteTimestampLabel.attributedText = attributedString
    }
}
