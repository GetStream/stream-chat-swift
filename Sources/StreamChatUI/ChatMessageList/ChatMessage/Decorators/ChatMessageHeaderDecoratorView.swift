//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public struct ChatChannelMessageHeaderDecoratorViewContent {
    public let message: ChatMessage
    public let channel: ChatChannel
    public let dateFormatter: MessageDateSeparatorFormatter
    public let shouldShowDate: Bool
    public let shouldShowUnreadMessages: Bool

    public init(
        message: ChatMessage,
        channel: ChatChannel,
        dateFormatter: MessageDateSeparatorFormatter,
        shouldShowDate: Bool,
        shouldShowUnreadMessages: Bool
    ) {
        self.message = message
        self.channel = channel
        self.dateFormatter = dateFormatter
        self.shouldShowDate = shouldShowDate
        self.shouldShowUnreadMessages = shouldShowUnreadMessages
    }
}

/// The decorator view that is used as a container for the chat message header view decorators.
public final class ChatChannelMessageHeaderDecoratorView: ChatMessageDecorationView, ThemeProvider {
    /// The container for the stacked views.
    public private(set) lazy var container = UIStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "chatMessageHeaderDecoratorView")

    public private(set) lazy var dateView = components.messageListDateSeparatorView.init()
        .withoutAutoresizingMaskConstraints
    public private(set) lazy var unreadCountView = components.unreadMessagesCounterDecorationView.init()
        .withoutAutoresizingMaskConstraints

    public var content: ChatChannelMessageHeaderDecoratorViewContent? {
        didSet {
            updateContentIfNeeded()
        }
    }

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
