//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A subclass of `UITableViewCell` that contains the `ChatThreadListItemView`.
open class ChatThreadListItemCell: _TableViewCell, ThemeProvider {
    /// The `ChatThreadListItemView` instance used as content view.
    open private(set) lazy var itemView: ChatThreadListItemView = components
        .threadListItemView
        .init()
        .withoutAutoresizingMaskConstraints

    override open var isSelected: Bool {
        didSet {
            itemView.backgroundColor = isSelected
                ? itemView.contentHighlightedBackgroundColor
                : itemView.contentBackgroundColor
        }
    }

    override open var isHighlighted: Bool {
        didSet {
            itemView.backgroundColor = isHighlighted
                ? itemView.contentHighlightedBackgroundColor
                : itemView.contentBackgroundColor
        }
    }

    override open func setUpLayout() {
        super.setUpLayout()

        contentView.embed(itemView)
    }
}
