//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The decorator view that is used to display the replies count in a thread
open class ChatThreadRepliesCountDecorationView: ChatMessageDecorationView, ThemeProvider {
    public var content: ChatMessage? {
        didSet {
            updateContentIfNeeded()
        }
    }

    lazy var messagesCountDecorationView = components.messagesCountDecorationView.init()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()

        embed(messagesCountDecorationView, insets: .init(top: 0, leading: 0, bottom: 8, trailing: 0))
    }

    override open func updateContent() {
        super.updateContent()

        messagesCountDecorationView.textLabel.text = L10n.Message.Thread.Replies.count(content?.replyCount ?? 0)
    }
}
