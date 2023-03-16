//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatUnreadMessagesCountDecorationView: ChatMessageDecorationView {
    public var content: ChatChannel? {
        didSet {
            updateContentIfNeeded()
        }
    }

    #warning("No need for components here?")
    lazy var messagesCountDecorationView = ChatMessagesCountDecorationView()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()

        embed(messagesCountDecorationView, insets: .init(top: 8, leading: 0, bottom: 0, trailing: 0))
    }

    override open func updateContent() {
        super.updateContent()

        let unreadCount = content?.unreadCount.messages ?? 0
        messagesCountDecorationView.textLabel.text = L10n.Message.Unread.count(unreadCount)
    }
}
