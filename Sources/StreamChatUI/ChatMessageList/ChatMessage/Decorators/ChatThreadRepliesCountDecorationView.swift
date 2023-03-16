//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatThreadRepliesCountDecorationView: ChatMessageDecorationView {
    public var content: ChatMessage? {
        didSet {
            updateContentIfNeeded()
        }
    }

    lazy var messagesCountDecorationView = ChatMessagesCountDecorationView()
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
