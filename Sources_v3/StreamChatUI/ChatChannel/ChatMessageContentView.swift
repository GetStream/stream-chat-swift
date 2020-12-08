//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageContentView<ExtraData: UIExtraDataTypes>: View, UIConfigProvider {
    public var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    public private(set) lazy var messageBubbleView = uiConfig
        .messageList
        .messageContentSubviews
        .bubbleView
        .init(showRepliedMessage: true)
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var messageMetadataView = uiConfig
        .messageList
        .messageContentSubviews
        .metadataView
        .init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var authorAvatarView = uiConfig
        .messageList
        .messageContentSubviews
        .authorAvatarView
        .init()
        .withoutAutoresizingMaskConstraints

    let messageReactionsView = ChatMessageReactionsView().withoutAutoresizingMaskConstraints

    private var incomingMessageConstraints: [NSLayoutConstraint] = []
    private var outgoingMessageConstraints: [NSLayoutConstraint] = []
    private var bubbleToReactionsConstraint: NSLayoutConstraint?
    private var bubbleToMetadataConstraint: NSLayoutConstraint?

    // MARK: - Overrides

    override open func setUpLayout() {
        addSubview(messageBubbleView)
        addSubview(messageMetadataView)
        addSubview(authorAvatarView)
        addSubview(messageReactionsView)

        NSLayoutConstraint.activate([
            authorAvatarView.widthAnchor.constraint(equalToConstant: 32),
            authorAvatarView.heightAnchor.constraint(equalToConstant: 32),
            authorAvatarView.leadingAnchor.constraint(equalTo: leadingAnchor),
            authorAvatarView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            messageReactionsView.topAnchor.constraint(equalTo: topAnchor),
            messageReactionsView.bottomAnchor.constraint(equalTo: messageBubbleView.topAnchor),
            
            messageBubbleView.trailingAnchor.constraint(equalTo: trailingAnchor),
            messageBubbleView.topAnchor.constraint(equalTo: topAnchor).with(priority: .defaultHigh),
            messageBubbleView.bottomAnchor.constraint(equalTo: bottomAnchor).with(priority: .defaultHigh),

            messageMetadataView.heightAnchor.constraint(equalToConstant: 16),
            messageMetadataView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        incomingMessageConstraints = [
            messageReactionsView.centerXAnchor.constraint(equalTo: messageBubbleView.trailingAnchor),
            messageMetadataView.leadingAnchor.constraint(equalTo: messageBubbleView.leadingAnchor),
            messageBubbleView.leadingAnchor.constraint(
                equalToSystemSpacingAfter: authorAvatarView.trailingAnchor,
                multiplier: 1
            )
        ]

        outgoingMessageConstraints = [
            messageReactionsView.centerXAnchor.constraint(equalTo: messageBubbleView.leadingAnchor),
            messageMetadataView.trailingAnchor.constraint(equalTo: messageBubbleView.trailingAnchor),
            messageBubbleView.leadingAnchor.constraint(equalTo: leadingAnchor)
        ]

        bubbleToReactionsConstraint = messageBubbleView.topAnchor.constraint(
            equalTo: messageReactionsView.bottomAnchor
        )
        bubbleToMetadataConstraint = messageMetadataView.topAnchor.constraint(
            equalToSystemSpacingBelow: messageBubbleView.bottomAnchor,
            multiplier: 1
        )
    }

    override open func updateContent() {
        messageBubbleView.message = message
        messageMetadataView.message = message
        if message?.isSentByCurrentUser ?? false {
            messageReactionsView.style = .smallOutgoing
        } else {
            messageReactionsView.style = .smallIncoming
        }
        messageReactionsView.reload(from: message?.message)

        let placeholder = UIImage(named: "pattern1", in: .streamChatUI)
        if let imageURL = message?.author.imageURL {
            authorAvatarView.imageView.setImage(from: imageURL, placeholder: placeholder)
        } else {
            authorAvatarView.imageView.image = placeholder
        }

        incomingMessageConstraints.forEach { $0.isActive = message?.isSentByCurrentUser == false }
        outgoingMessageConstraints.forEach { $0.isActive = message?.isSentByCurrentUser == true }
        bubbleToReactionsConstraint?.isActive = message?.deletedAt == nil && !(message?.reactionScores.isEmpty ?? true)
        bubbleToMetadataConstraint?.isActive = message?.isLastInGroup == true

        authorAvatarView.isVisible = message?.isSentByCurrentUser == false && message?.isLastInGroup == true
        messageMetadataView.isVisible = bubbleToMetadataConstraint?.isActive ?? false
        messageReactionsView.isVisible = bubbleToReactionsConstraint?.isActive ?? false
    }
}
