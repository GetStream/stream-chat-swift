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

        // this one is ugly: reactions view is part of message content, but is not part of it frame horizontally.
        // In same time we want to prevent reactions view to slip out of screen / cell.
        // We maybe should rethink layout of content view and make reactions part of frame horizontally as well.
        // This will solve superview access hack
        if let superview = self.superview {
            messageReactionsView.trailingAnchor.constraint(lessThanOrEqualTo: superview.trailingAnchor).isActive = true
            messageReactionsView.leadingAnchor.constraint(greaterThanOrEqualTo: superview.leadingAnchor).isActive = true
        }

        incomingMessageConstraints = [
            messageReactionsView.centerXAnchor.constraint(equalTo: messageBubbleView.trailingAnchor),
            messageReactionsView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
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
            messageReactionsView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            messageMetadataView.trailingAnchor.constraint(equalTo: messageBubbleView.trailingAnchor).with(priority: .defaultHigh),
            messageBubbleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            threadArrowView.trailingAnchor.constraint(equalTo: messageBubbleView.trailingAnchor),
            threadView.trailingAnchor.constraint(equalTo: threadArrowView.leadingAnchor)
        ]

        bubbleToReactionsConstraint = messageBubbleView.topAnchor.constraint(
            equalTo: messageReactionsView.centerYAnchor
        )
        bubbleToMetadataConstraint = messageMetadataView.topAnchor.constraint(
            equalToSystemSpacingBelow: messageBubbleView.bottomAnchor,
            multiplier: 1
        )
    }

    override open func updateContent() {
        var toActivate: [NSLayoutConstraint] = []
        var toDeactivate: [NSLayoutConstraint] = []

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
        if isPartOfThread {
            if isOutgoing {
                toActivate.append(contentsOf: outgoingMessageIsThreadConstraints)
                toDeactivate.append(contentsOf: incomingMessageIsThreadConstraints)
            } else {
                toActivate.append(contentsOf: incomingMessageIsThreadConstraints)
                toDeactivate.append(contentsOf: outgoingMessageIsThreadConstraints)
            }
        } else {
            toDeactivate.append(contentsOf: outgoingMessageIsThreadConstraints)
            toDeactivate.append(contentsOf: incomingMessageIsThreadConstraints)
        }

        let placeholder = UIImage(named: "pattern1", in: .streamChatUI)
        if let imageURL = message?.author.imageURL {
            authorAvatarView.imageView.setImage(from: imageURL, placeholder: placeholder)
        } else {
            authorAvatarView.imageView.image = placeholder
        }

        if isOutgoing {
            toActivate.append(contentsOf: outgoingMessageConstraints)
            toDeactivate.append(contentsOf: incomingMessageConstraints)
        } else {
            toActivate.append(contentsOf: incomingMessageConstraints)
            toDeactivate.append(contentsOf: outgoingMessageConstraints)
        }

        if message?.deletedAt == nil, !(message?.reactionScores.isEmpty ?? true) {
            toActivate.append(bubbleToReactionsConstraint!)
        } else {
            toDeactivate.append(bubbleToReactionsConstraint!)
        }
        
        if message?.isLastInGroup == true {
            toActivate.append(bubbleToMetadataConstraint!)
        } else {
            toDeactivate.append(bubbleToMetadataConstraint!)
        }

        NSLayoutConstraint.deactivate(toDeactivate)
        NSLayoutConstraint.activate(toActivate)

        authorAvatarView.isVisible = !isOutgoing && message?.isLastInGroup == true
        messageMetadataView.isVisible = bubbleToMetadataConstraint?.isActive ?? false
        messageReactionsView.isVisible = bubbleToReactionsConstraint?.isActive ?? false
    }

    // MARK: - Actions

    @objc func didTapOnThread() {
        onThreadTap(message)
    }
}
