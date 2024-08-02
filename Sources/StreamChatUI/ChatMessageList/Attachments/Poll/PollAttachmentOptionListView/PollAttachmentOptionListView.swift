//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The options list view of the poll attachment.
open class PollAttachmentOptionListView: _View, ThemeProvider {
    // MARK: - Content

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

    // MARK: - Configuration

    public var maximumNumberOfVisibleOptions = 10

    /// A closure that is triggered whenever the option is tapped either from the button or the item itself.
    public var onOptionTap: ((PollOption) -> Void)?

    // MARK: - Views

    /// The item views that display each option.
    ///
    /// The number of views is constant dependent on `maximumNumberOfVisibleOptions`.
    /// This is to make sure views are not re-created dependent on the content.
    /// Hiding/Showing views has better performance than re-creating the views from scratch.
    open lazy var itemViews: [PollAttachmentOptionListItemView] = {
        (0...maximumNumberOfVisibleOptions - 1).map { _ in
            let view = self.components.pollAttachmentOptionListItemView.init()
            view.onOptionTap = { option in
                self.onOptionTap?(option)
            }
            return view
        }
    }()

    // MARK: - Lifecycle

    override open func setUpLayout() {
        super.setUpLayout()

        VContainer(spacing: 24) {
            itemViews
        }.embed(in: self)
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else {
            return
        }

        itemViews.forEach {
            $0.isHidden = true
        }
        zip(itemViews, content.poll.options).forEach { itemView, option in
            itemView.content = .init(
                option: option,
                isVotedByCurrentUser: content.poll.hasCurrentUserVoted(forOption: option)
            )
            itemView.isHidden = false
        }
    }
}
