//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageContentView = _ChatMessageContentView<NoExtraData>

open class _ChatMessageContentView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    public var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    public var onThreadTap: (_ChatMessageGroupPart<ExtraData>?) -> Void = { _ in }
    public var onErrorIndicatorTap: (_ChatMessageGroupPart<ExtraData>?) -> Void = { _ in }
    public var onLinkTap: (_ChatMessageAttachment<ExtraData>?) -> Void = { _ in } {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    public private(set) lazy var messageBubbleView = uiConfig
        .messageList
        .messageContentSubviews
        .bubbleView.init()
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
        messageBubbleView.onLinkTap = onLinkTap
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
            threadView.bottomAnchor.pin(equalTo: bottomAnchor),
            messageMetadataView.leadingAnchor.pin(equalToSystemSpacingAfter: threadView.trailingAnchor, multiplier: 1)
        ]

        outgoingMessageIsThreadConstraints = [
            threadView.bottomAnchor.pin(equalTo: bottomAnchor),
            threadView.leadingAnchor.pin(equalToSystemSpacingAfter: messageMetadataView.trailingAnchor, multiplier: 1)
        ]

        NSLayoutConstraint.activate([
            authorAvatarView.widthAnchor.pin(equalToConstant: 32),
            authorAvatarView.heightAnchor.pin(equalToConstant: 32),
            authorAvatarView.leadingAnchor.pin(equalTo: leadingAnchor),
            authorAvatarView.bottomAnchor.pin(equalTo: bottomAnchor),
            
            reactionsBubble.topAnchor.pin(equalTo: topAnchor),
            
            messageBubbleView.trailingAnchor.pin(equalTo: trailingAnchor).almostRequired,
            messageBubbleView.topAnchor.pin(equalTo: topAnchor).with(priority: .defaultHigh),
            messageBubbleView.bottomAnchor.pin(equalTo: bottomAnchor).with(priority: .defaultHigh),
            
            messageMetadataView.heightAnchor.pin(equalToConstant: 16),
            messageMetadataView.bottomAnchor.pin(equalTo: bottomAnchor),
            
            threadArrowView.widthAnchor.pin(equalToConstant: 16),
            threadArrowView.topAnchor.pin(equalTo: messageBubbleView.centerYAnchor),
            threadArrowView.bottomAnchor.pin(equalTo: threadView.centerYAnchor),
            
            threadView.topAnchor.pin(equalToSystemSpacingBelow: messageBubbleView.bottomAnchor, multiplier: 1),
            
            errorIndicator.bottomAnchor.pin(equalTo: messageBubbleView.bottomAnchor),
            errorIndicator.trailingAnchor.pin(equalTo: trailingAnchor)
        ])

        // this one is ugly: reactions view is part of message content, but is not part of it frame horizontally.
        // In same time we want to prevent reactions view to slip out of screen / cell.
        // We maybe should rethink layout of content view and make reactions part of frame horizontally as well.
        // This will solve superview access hack
        if let superview = self.superview {
            reactionsBubble.trailingAnchor.pin(lessThanOrEqualTo: superview.trailingAnchor).isActive = true
            reactionsBubble.leadingAnchor.pin(greaterThanOrEqualTo: superview.leadingAnchor).isActive = true
        }

        incomingMessageConstraints = [
            reactionsBubble.centerXAnchor.pin(equalTo: messageBubbleView.trailingAnchor, constant: 8),
            reactionsBubble.tailLeadingAnchor.pin(equalTo: messageBubbleView.trailingAnchor, constant: -5),
            
            messageMetadataView.leadingAnchor.pin(equalTo: messageBubbleView.leadingAnchor).with(priority: .defaultHigh),
            messageBubbleView.leadingAnchor.pin(
                equalToSystemSpacingAfter: authorAvatarView.trailingAnchor,
                multiplier: 1
            ),
            threadArrowView.leadingAnchor.pin(equalTo: messageBubbleView.leadingAnchor),
            threadView.leadingAnchor.pin(equalTo: threadArrowView.trailingAnchor)
        ]

        outgoingMessageConstraints = [
            reactionsBubble.centerXAnchor.pin(equalTo: messageBubbleView.leadingAnchor, constant: -8),
            reactionsBubble.tailTrailingAnchor.pin(equalTo: messageBubbleView.leadingAnchor, constant: 5),
            
            messageMetadataView.trailingAnchor.pin(equalTo: messageBubbleView.trailingAnchor).with(priority: .defaultHigh),
            messageBubbleView.leadingAnchor.pin(equalTo: leadingAnchor),
            threadArrowView.trailingAnchor.pin(equalTo: messageBubbleView.trailingAnchor),
            threadView.trailingAnchor.pin(equalTo: threadArrowView.leadingAnchor)
        ]

        bubbleToReactionsConstraint = messageBubbleView.topAnchor.pin(
            equalTo: reactionsBubble.centerYAnchor
        )
        bubbleToMetadataConstraint = messageMetadataView.topAnchor.pin(
            equalToSystemSpacingBelow: messageBubbleView.bottomAnchor,
            multiplier: 1
        )
        bubbleToErrorIndicatorConstraint = messageBubbleView.trailingAnchor.pin(
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

        messageBubbleView.onLinkTap = onLinkTap
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
