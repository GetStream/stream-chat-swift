//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The item view that displays information in a poll comment item cell.
open class PollCommentListItemView: _View, ThemeProvider {
    public struct Content {
        public var comment: PollVote
        public var poll: Poll

        public init(
            comment: PollVote,
            poll: Poll
        ) {
            self.comment = comment
            self.poll = poll
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The view that display a vote, since a vote can be a answer/comment.
    /// By default in the SDK a comment has the same UI as a vote, so we reuse the vote item view.
    open private(set) lazy var voteItemView: PollResultsVoteItemView = components
        .pollResultsVoteItemView.init()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()

        embed(voteItemView, insets: .init(top: 4, leading: 0, bottom: 4, trailing: 0))
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else { return }

        voteItemView.content = .init(vote: content.comment, poll: content.poll)
    }
}
