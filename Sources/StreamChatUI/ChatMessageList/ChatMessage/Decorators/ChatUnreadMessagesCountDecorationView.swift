//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The decorator view that is used to display the unread messages count in a channel.
open class ChatUnreadMessagesCountDecorationView: ChatMessageDecorationView, ThemeProvider {
    public var content: ChatChannel? {
        didSet {
            updateContentIfNeeded()
        }
    }

    lazy var messagesCountDecorationView = components.messagesCountDecorationView.init()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()

        embed(messagesCountDecorationView, insets: .init(top: 8, leading: 0, bottom: 0, trailing: 0))
    }

    override open func updateContent() {
        super.updateContent()

        // Temporarily disabling unread counts as they are not 100% accurate all the time.
        // Passing 0 will show "Unread messages" without a number
        // let unreadCount = content?.unreadCount.messages ?? 0
        // TODO: https://github.com/GetStream/ios-issues-tracking/issues/527
        let unreadCount = 0
        messagesCountDecorationView.textLabel.text = L10n.Message.Unread.count(unreadCount)
    }
}
