//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageContentView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    public var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    public var onThreadTap: (_ChatMessageGroupPart<ExtraData>?) -> Void = { _ in }

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

    let messageReactionsView = ChatMessageReactionsView<ExtraData>().withoutAutoresizingMaskConstraints

    public private(set) lazy var threadArrowView = uiConfig
        .messageList
        .messageContentSubviews
        .threadArrowView
        .init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var threadView = uiConfig
        .messageList
        .messageContentSubviews
        .threadInfoView
        .init()
        .withoutAutoresizingMaskConstraints

    private var incomingMessageConstraints: [NSLayoutConstraint] = []
    private var outgoingMessageConstraints: [NSLayoutConstraint] = []
    private var bubbleToReactionsConstraint: NSLayoutConstraint?
    private var bubbleToMetadataConstraint: NSLayoutConstraint?

    private var incomingMessageIsThreadConstraints: [NSLayoutConstraint] = []
    private var outgoingMessageIsThreadConstraints: [NSLayoutConstraint] = []

    // MARK: - Overrides

    override open func setUp() {
        super.setUp()
        threadView.addTarget(self, action: #selector(didTapOnThread), for: .touchUpInside)
    }

    override open func setUpLayout() {
        addSubview(messageBubbleView)
        addSubview(messageMetadataView)
        addSubview(authorAvatarView)
        addSubview(messageReactionsView)
        addSubview(threadArrowView)
        addSubview(threadView)

        incomingMessageIsThreadConstraints = [
            threadView.bottomAnchor.constraint(equalTo: bottomAnchor),
            messageMetadataView.leadingAnchor.constraint(equalToSystemSpacingAfter: threadView.trailingAnchor, multiplier: 1)
        ]

        outgoingMessageIsThreadConstraints = [
            threadView.bottomAnchor.constraint(equalTo: bottomAnchor),
            threadView.leadingAnchor.constraint(equalToSystemSpacingAfter: messageMetadataView.trailingAnchor, multiplier: 1)
        ]

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
            messageMetadataView.bottomAnchor.constraint(equalTo: bottomAnchor),

            threadArrowView.widthAnchor.constraint(equalToConstant: 16),
            threadArrowView.topAnchor.constraint(equalTo: messageBubbleView.centerYAnchor),
            threadArrowView.bottomAnchor.constraint(equalTo: threadView.centerYAnchor),

            threadView.topAnchor.constraint(equalToSystemSpacingBelow: messageBubbleView.bottomAnchor, multiplier: 1)
        ])

        incomingMessageConstraints = [
            messageReactionsView.centerXAnchor.constraint(equalTo: messageBubbleView.trailingAnchor),
            messageMetadataView.leadingAnchor.constraint(equalTo: messageBubbleView.leadingAnchor).with(priority: .defaultHigh),
            messageBubbleView.leadingAnchor.constraint(
                equalToSystemSpacingAfter: authorAvatarView.trailingAnchor,
                multiplier: 1
            ),
            threadArrowView.leadingAnchor.constraint(equalTo: messageBubbleView.leadingAnchor),
            threadView.leadingAnchor.constraint(equalTo: threadArrowView.trailingAnchor)
        ]

        outgoingMessageConstraints = [
            messageReactionsView.centerXAnchor.constraint(equalTo: messageBubbleView.leadingAnchor),
            messageMetadataView.trailingAnchor.constraint(equalTo: messageBubbleView.trailingAnchor).with(priority: .defaultHigh),
            messageBubbleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            threadArrowView.trailingAnchor.constraint(equalTo: messageBubbleView.trailingAnchor),
            threadView.trailingAnchor.constraint(equalTo: threadArrowView.leadingAnchor)
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
        let isOutgoing = message?.isSentByCurrentUser ?? false
        let isPartOfThread = message?.isPartOfThread ?? false

        messageBubbleView.message = message
        messageMetadataView.message = message
        threadView.message = message

        if isOutgoing {
            messageReactionsView.style = .smallOutgoing
            threadArrowView.direction = .toLeading
        } else {
            messageReactionsView.style = .smallIncoming
            threadArrowView.direction = .toTrailing
        }
        messageReactionsView.reload(from: message?.message)

        threadView.isHidden = !isPartOfThread
        threadArrowView.isHidden = !isPartOfThread
        outgoingMessageIsThreadConstraints.forEach { $0.isActive = isPartOfThread && isOutgoing }
        incomingMessageIsThreadConstraints.forEach { $0.isActive = isPartOfThread && !isOutgoing }

        let placeholder = UIImage(named: "pattern1", in: .streamChatUI)
        if let imageURL = message?.author.imageURL {
            authorAvatarView.imageView.setImage(from: imageURL, placeholder: placeholder)
        } else {
            authorAvatarView.imageView.image = placeholder
        }

        incomingMessageConstraints.forEach { $0.isActive = !isOutgoing }
        outgoingMessageConstraints.forEach { $0.isActive = isOutgoing }
        bubbleToReactionsConstraint?.isActive = message?.deletedAt == nil && !(message?.reactionScores.isEmpty ?? true)
        bubbleToMetadataConstraint?.isActive = message?.isLastInGroup == true

        authorAvatarView.isVisible = !isOutgoing && message?.isLastInGroup == true
        messageMetadataView.isVisible = bubbleToMetadataConstraint?.isActive ?? false
        messageReactionsView.isVisible = bubbleToReactionsConstraint?.isActive ?? false
    }

    // MARK: - Actions

    @objc func didTapOnThread() {
        onThreadTap(message)
    }
}
