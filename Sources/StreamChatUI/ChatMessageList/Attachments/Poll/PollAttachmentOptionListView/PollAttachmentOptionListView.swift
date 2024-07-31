//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The options list view of the poll attachment.
open class PollAttachmentOptionListView: _View, ThemeProvider {
    public struct Content: Equatable {
        public var options: [PollOption]
    }

    public var content: Content? {
        didSet {
            if oldValue != content {
                updateContentIfNeeded()
            }
        }
    }

    /// The container responsible to render each option in a vertical stack.
    /// Whenever the content changes, the stack view is rebuilt.
    open var container: UIStackView? {
        didSet {
            oldValue?.removeFromSuperview()
        }
    }

    override open func updateContent() {
        super.updateContent()

        container = VContainer(spacing: 24) {
            itemViews
        }.embed(in: self)
    }

    /// The option item views.
    open var itemViews: [UIView] {
        content?.options.map { option in
            components.pollAttachmentOptionListItemView.init(content: .init(option: option))
        } ?? []
    }
}
