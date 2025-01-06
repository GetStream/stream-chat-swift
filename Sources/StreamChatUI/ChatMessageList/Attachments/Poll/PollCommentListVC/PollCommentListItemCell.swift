//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The `UITableViewCell` for the poll comment list item cell.
open class PollCommentListItemCell: _TableViewCell, ThemeProvider {
    public struct Content {
        public var comment: PollVote
        public var poll: Poll

        public init(comment: PollVote, poll: Poll) {
            self.comment = comment
            self.poll = poll
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The actual comment item view that the cell displays.
    open private(set) lazy var itemView: PollCommentListItemView = components
        .pollCommentListItemView.init()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()

        embed(itemView, insets: .init(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    override open func updateContent() {
        guard let content = self.content else { return }
        itemView.content = .init(comment: content.comment, poll: content.poll)
    }
}
