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
    public var onErrorIndicatorTap: (_ChatMessageGroupPart<ExtraData>?) -> Void = { _ in }

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

    public private(set) lazy var reactionsBubble = uiConfig
        .messageList
        .messageReactions
        .reactionsBubbleView
        .init()
        .withoutAutoresizingMaskConstraints

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

    public private(set) lazy var errorIndicator = uiConfig
        .messageList
        .messageContentSubviews
        .errorIndicator
        .init()
        .withoutAutoresizingMaskConstraints

    private var incomingMessageConstraints: [NSLayoutConstraint] = []
    private var outgoingMessageConstraints: [NSLayoutConstraint] = []
    private var bubbleToReactionsConstraint: NSLayoutConstraint?
    private var bubbleToMetadataConstraint: NSLayoutConstraint?
    private var bubbleToErrorIndicatorConstraint: NSLayoutConstraint?

    private var incomingMessageIsThreadConstraints: [NSLayoutConstraint] = []
    private var outgoingMessageIsThreadConstraints: [NSLayoutConstraint] = []

    // MARK: - Overrides

    override open func setUp() {
        super.setUp()

        reactionsBubble.isUserInteractionEnabled = false
        threadView.addTarget(self, action: #selector(didTapOnThread), for: .touchUpInside)
        errorIndicator.addTarget(self, action: #selector(didTapOnErrorIndicator), for: .touchUpInside)
    }

    override open func setUpLayout() {
        addSubview(messageBubbleView)
        addSubview(messageMetadataView)
        addSubview(authorAvatarView)
        addSubview(reactionsBubble)
        addSubview(threadArrowView)
        addSubview(threadView)
        addSubview(errorIndicator)

        errorIndicator.setContentCompressionResistancePriority(.required, for: .horizontal)
        errorIndicator.setContentCompressionResistancePriority(.required, for: .vertical)

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
            
            reactionsBubble.topAnchor.constraint(equalTo: topAnchor),
            
            messageBubbleView.trailingAnchor.constraint(equalTo: trailingAnchor).almostRequired,
            messageBubbleView.topAnchor.constraint(equalTo: topAnchor).with(priority: .defaultHigh),
            messageBubbleView.bottomAnchor.constraint(equalTo: bottomAnchor).with(priority: .defaultHigh),
            
            messageMetadataView.heightAnchor.constraint(equalToConstant: 16),
            messageMetadataView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            threadArrowView.widthAnchor.constraint(equalToConstant: 16),
            threadArrowView.topAnchor.constraint(equalTo: messageBubbleView.centerYAnchor),
            threadArrowView.bottomAnchor.constraint(equalTo: threadView.centerYAnchor),
            
            threadView.topAnchor.constraint(equalToSystemSpacingBelow: messageBubbleView.bottomAnchor, multiplier: 1),
            
            errorIndicator.bottomAnchor.constraint(equalTo: messageBubbleView.bottomAnchor),
            errorIndicator.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        // this one is ugly: reactions view is part of message content, but is not part of it frame horizontally.
        // In same time we want to prevent reactions view to slip out of screen / cell.
        // We maybe should rethink layout of content view and make reactions part of frame horizontally as well.
        // This will solve superview access hack
        if let superview = self.superview {
            reactionsBubble.trailingAnchor.constraint(lessThanOrEqualTo: superview.trailingAnchor).isActive = true
            reactionsBubble.leadingAnchor.constraint(greaterThanOrEqualTo: superview.leadingAnchor).isActive = true
        }

        incomingMessageConstraints = [
            reactionsBubble.centerXAnchor.constraint(equalTo: messageBubbleView.trailingAnchor, constant: 8),
            reactionsBubble.tailLeadingAnchor.constraint(equalTo: messageBubbleView.trailingAnchor, constant: -5),
            
            messageMetadataView.leadingAnchor.constraint(equalTo: messageBubbleView.leadingAnchor).with(priority: .defaultHigh),
            messageBubbleView.leadingAnchor.constraint(
                equalToSystemSpacingAfter: authorAvatarView.trailingAnchor,
                multiplier: 1
            ),
            threadArrowView.leadingAnchor.constraint(equalTo: messageBubbleView.leadingAnchor),
            threadView.leadingAnchor.constraint(equalTo: threadArrowView.trailingAnchor)
        ]

        outgoingMessageConstraints = [
            reactionsBubble.centerXAnchor.constraint(equalTo: messageBubbleView.leadingAnchor, constant: -8),
            reactionsBubble.tailTrailingAnchor.constraint(equalTo: messageBubbleView.leadingAnchor, constant: 5),
            
            messageMetadataView.trailingAnchor.constraint(equalTo: messageBubbleView.trailingAnchor).with(priority: .defaultHigh),
            messageBubbleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            threadArrowView.trailingAnchor.constraint(equalTo: messageBubbleView.trailingAnchor),
            threadView.trailingAnchor.constraint(equalTo: threadArrowView.leadingAnchor)
        ]

        bubbleToReactionsConstraint = messageBubbleView.topAnchor.constraint(
            equalTo: reactionsBubble.centerYAnchor
        )
        bubbleToMetadataConstraint = messageMetadataView.topAnchor.constraint(
            equalToSystemSpacingBelow: messageBubbleView.bottomAnchor,
            multiplier: 1
        )
        bubbleToErrorIndicatorConstraint = messageBubbleView.trailingAnchor.constraint(
            equalTo: errorIndicator.centerXAnchor
        )
    }

    override open func updateContent() {
        // When message cell is about to be reused, it sets `nil` for message value.
        // That means we need to remove all dynamic constraints to prevent layout warnings.
        guard let message = self.message else {
            NSLayoutConstraint.deactivate(outgoingMessageConstraints)
            NSLayoutConstraint.deactivate(incomingMessageConstraints)
            NSLayoutConstraint.deactivate(outgoingMessageIsThreadConstraints)
            NSLayoutConstraint.deactivate(incomingMessageIsThreadConstraints)
            bubbleToReactionsConstraint?.isActive = false
            bubbleToErrorIndicatorConstraint?.isActive = false
            bubbleToMetadataConstraint?.isActive = false
            return
        }

        var toActivate: [NSLayoutConstraint] = []
        var toDeactivate: [NSLayoutConstraint] = []

        let isOutgoing = message.isSentByCurrentUser
        let isPartOfThread = message.isPartOfThread

        messageBubbleView.message = message
        messageMetadataView.message = message
        threadView.message = message
        threadArrowView.direction = isOutgoing ? .toLeading : .toTrailing

        let userReactionIDs = Set(message.currentUserReactions.map(\.type))

        reactionsBubble.content = .init(
            style: isOutgoing ? .smallOutgoing : .smallIncoming,
            reactions: message.message.reactionScores.keys
                .sorted { $0.rawValue < $1.rawValue }
                .map { .init(type: $0, isChosenByCurrentUser: userReactionIDs.contains($0)) },
            didTapOnReaction: { _ in }
        )

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
        if let imageURL = message.author.imageURL {
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

        if message.deletedAt == nil, !message.reactionScores.isEmpty {
            toActivate.append(bubbleToReactionsConstraint!)
        } else {
            toDeactivate.append(bubbleToReactionsConstraint!)
        }
        
        if message.isLastInGroup {
            toActivate.append(bubbleToMetadataConstraint!)
        } else {
            toDeactivate.append(bubbleToMetadataConstraint!)
        }

        if message.lastActionFailed {
            toActivate.append(bubbleToErrorIndicatorConstraint!)
        } else {
            toDeactivate.append(bubbleToErrorIndicatorConstraint!)
        }

        NSLayoutConstraint.deactivate(toDeactivate)
        NSLayoutConstraint.activate(toActivate)

        authorAvatarView.isVisible = !isOutgoing && message.isLastInGroup
        messageMetadataView.isVisible = bubbleToMetadataConstraint?.isActive ?? false
        reactionsBubble.isVisible = bubbleToReactionsConstraint?.isActive ?? false
        errorIndicator.isVisible = message.lastActionFailed
    }

    // MARK: - Actions

    @objc open func didTapOnErrorIndicator() {
        onErrorIndicatorTap(message)
    }

    @objc func didTapOnThread() {
        onThreadTap(message)
    }
}
