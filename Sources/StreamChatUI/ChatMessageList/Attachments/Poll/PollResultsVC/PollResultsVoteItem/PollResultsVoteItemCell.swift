//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The `UITableViewCell` for the poll results vote item.
open class PollResultsVoteItemCell: _TableViewCell, ThemeProvider {
    public struct Content {
        public var vote: PollVote

        public init(vote: PollVote) {
            self.vote = vote
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The actual pole vote item view that the cell displays.
    open private(set) lazy var itemView: PollResultsVoteItemView = components
        .pollResultsVoteItemView.init()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()

        embed(itemView, insets: .init(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    override open func updateContent() {
        guard let content = self.content else { return }
        itemView.content = .init(vote: content.vote)
    }
}
