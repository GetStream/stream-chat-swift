//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The vote item view that displays information in a poll results cell.
open class PollResultsVoteItemView: _View, ThemeProvider {
    public struct Content {
        public var vote: PollVote

        public init(
            vote: PollVote
        ) {
            self.vote = vote
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

        backgroundColor = appearance.colorPalette.background1
        authorAvatarView.shouldShowOnlineIndicator = false
        authorNameLabel.font = appearance.fonts.body
        authorNameLabel.textColor = appearance.colorPalette.text
        voteTimestampLabel.font = appearance.fonts.footnote
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
        authorAvatarView.content = content?.vote.user
        authorNameLabel.text = content?.vote.user?.name
        if #available(iOS 15.0, *) {
            voteTimestampLabel.text = content?.vote.createdAt.formatted(.dateTime)
        } else {
            // Fallback on earlier versions
        }
    }
}
