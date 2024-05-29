//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that shows a number of unread messages in channel.
open class ChatChannelUnreadCountView: _View, ThemeProvider, SwiftUIRepresentable {
    /// The badge view that displays the unread count.
    open private(set) lazy var badgeView = components.badgeView.init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "badgeView")

    /// The `UILabel` instance that holds number of unread messages.
    open private(set) lazy var unreadCountLabel = badgeView.textLabel
        .withAccessibilityIdentifier(identifier: "unreadCountLabel")

    /// The data this view component shows.
    open var content: ChannelUnreadCount = .noUnread {
        didSet { updateContentIfNeeded() }
    }

    override open func setUpLayout() {
        super.setUpLayout()

        embed(badgeView)
    }

    override open func updateContent() {
        isHidden = content.messages == 0
        unreadCountLabel.text = String(content.messages)
    }
}
