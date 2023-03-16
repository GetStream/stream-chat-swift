//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public struct ChatMessageHeaderDecoratorViewContent {
    let message: ChatMessage
    let channel: ChatChannel
    let dateFormatter: MessageDateSeparatorFormatter
    let shouldShowDate: Bool
    let shouldShowUnreadMessages: Bool
}

/// The decorator view that is used as a container for the chat message header view decorators.
public final class ChatMessageHeaderDecoratorView: ChatMessageDecorationView, ThemeProvider {
    /// The container for the stacked views.
    public private(set) lazy var container = UIStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "chatMessageHeaderDecoratorView")

    public private(set) lazy var dateView = components.messageListDateSeparatorView.init()
        .withoutAutoresizingMaskConstraints
    public private(set) lazy var unreadCountView = ChatUnreadMessagesCountDecorationView()
        .withoutAutoresizingMaskConstraints

    public var content: ChatMessageHeaderDecoratorViewContent?

    override public func setUpLayout() {
        super.setUpLayout()
        embed(container, insets: .init(top: 0, leading: 0, bottom: 0, trailing: 0))
        container.axis = .vertical
        container.spacing = 4

        [dateView, unreadCountView].forEach(container.addArrangedSubview)
    }

    override public func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = nil
    }

    override public func updateContent() {
        super.updateContent()
        dateView.isVisible = content?.shouldShowDate ?? false
        unreadCountView.isVisible = content?.shouldShowUnreadMessages ?? false
        dateView.content = content.map { $0.dateFormatter.format($0.message.createdAt) }
        unreadCountView.content = content?.channel
    }
}
