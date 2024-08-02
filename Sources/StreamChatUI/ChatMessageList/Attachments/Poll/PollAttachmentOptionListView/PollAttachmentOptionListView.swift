//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The options list view of the poll attachment.
open class PollAttachmentOptionListView: _View, ThemeProvider {
    public struct Content: Equatable {
        public var poll: Poll

        public init(poll: Poll) {
            self.poll = poll
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The container responsible to render each option in a vertical stack.
    /// Whenever the content changes, the stack view is rebuilt.
    open var container: UIStackView? {
        didSet {
            oldValue?.removeFromSuperview()
        }
    }

    /// A closure that is triggered whenever the option is tapped either from the button or the item itself.
    public var onOptionTap: ((PollOption) -> Void)?

    override open func updateContent() {
        super.updateContent()

        container = VContainer(spacing: 24) {
            itemViews
        }.embed(in: self)
    }

    /// The option item views.
    open var itemViews: [PollAttachmentOptionListItemView] {
        guard let content = self.content else { return [] }
        return content.poll.options.map { option in
            let view = components.pollAttachmentOptionListItemView.init()
            view.content = .init(
                option: option,
                isVotedByCurrentUser: content.poll.hasCurrentUserVoted(forOption: option)
            )
            view.onOptionTap = { option in
                self.onOptionTap?(option)
            }
            return view
        }
    }
}
