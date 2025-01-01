//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The options list view of the poll attachment.
open class PollAttachmentOptionListView: _View, ThemeProvider {
    // MARK: - Content

    public struct Content: Equatable {
        public var poll: Poll
        public var maxNumberOfVisibleOptions: Int?

        public init(
            poll: Poll,
            maxNumberOfVisibleOptions: Int?
        ) {
            self.poll = poll
            self.maxNumberOfVisibleOptions = maxNumberOfVisibleOptions
        }

        var options: [PollOption] {
            if let maxNumberOfVisibleOptions = maxNumberOfVisibleOptions {
                return Array(poll.options.prefix(maxNumberOfVisibleOptions))
            } else {
                return poll.options
            }
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    // MARK: - Configuration

    /// A closure that is triggered whenever the option is tapped either from the button or the item itself.
    public var onOptionTap: ((PollOption) -> Void)?

    // MARK: - Views

    /// The container that holds all option item views.
    open var container: UIStackView?

    /// The item views that display each option.
    open var itemViews: [PollAttachmentOptionListItemView] = []

    // MARK: - Lifecycle

    override open func setUpLayout() {
        super.setUpLayout()

        container?.removeFromSuperview()
        container = VContainer(spacing: 24) {
            makeItemViews()
        }.embed(in: self)
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else {
            return
        }

        /// We only recreate the item views in case the options do not match the number of views.
        /// This makes sure we only recreate the item views when needed.
        if itemViews.count != content.options.count {
            setUpLayout()
        }

        itemViews.forEach {
            $0.isHidden = true
        }
        zip(itemViews, content.options).forEach { itemView, option in
            itemView.content = .init(
                option: option,
                poll: content.poll
            )
            itemView.isHidden = false
        }
    }

    /// Creates the option item views based on the number of options.
    open func makeItemViews() -> [PollAttachmentOptionListItemView] {
        guard let content = self.content else { return [] }
        guard !content.options.isEmpty else { return [] }
        itemViews = (0..<content.options.count).map { _ in
            let view = self.components.pollAttachmentOptionListItemView.init()
            view.onOptionTap = { [weak self] option in
                self?.onOptionTap?(option)
            }
            return view
        }
        return itemViews
    }
}
