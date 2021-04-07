//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageContentView = _ChatMessageContentView<NoExtraData>

open class _ChatMessageContentView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    public var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    public var onThreadTap: (_ChatMessageGroupPart<ExtraData>?) -> Void = { _ in }
    public var onErrorIndicatorTap: (_ChatMessageGroupPart<ExtraData>?) -> Void = { _ in }
    public var onLinkTap: (ChatMessageDefaultAttachment?) -> Void = { _ in } {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    public var messageBubbleView: _ChatMessageBubbleView<ExtraData>?
    
    public var textView: UITextView?
    
    public var linkPreviewView: _ChatMessageLinkPreviewView<ExtraData>?
    
    public var messageQuoteView: _ChatMessageQuoteView<ExtraData>?
    
    public var attachmentsView: _ChatMessageAttachmentsView<ExtraData>?

    public var messageMetadataView: _ChatMessageMetadataView<ExtraData>?
    
    public var authorAvatarView: ChatAvatarView?

    public var reactionsBubble: _ChatMessageReactionsBubbleView<ExtraData>?

    public var threadArrowView: _ChatMessageThreadArrowView<ExtraData>?

    public var threadView: _ChatMessageThreadInfoView<ExtraData>?

    public var errorIndicator: _ChatMessageErrorIndicator<ExtraData>?

    var incomingMessageConstraints: [NSLayoutConstraint] = []
    var outgoingMessageConstraints: [NSLayoutConstraint] = []
    var bubbleToReactionsConstraint: NSLayoutConstraint?
    var bubbleToMetadataConstraint: NSLayoutConstraint?
    var bubbleToErrorIndicatorConstraint: NSLayoutConstraint?

    var incomingMessageIsThreadConstraints: [NSLayoutConstraint] = []
    var outgoingMessageIsThreadConstraints: [NSLayoutConstraint] = []
    
    var didSetUpConstraints = false

    // MARK: - Setup family of functions
    
    open func setupMessageBubbleView() {
        guard messageBubbleView == nil else { return }
        
        let messageBubbleView = uiConfig
            .messageList
            .messageContentSubviews
            .bubbleView.init()
            .withoutAutoresizingMaskConstraints
        self.messageBubbleView = messageBubbleView
        
        addSubview(messageBubbleView)
        
        constraintsToActivate += [
            messageBubbleView.topAnchor.pin(equalTo: topAnchor).with(priority: .defaultHigh),
            messageBubbleView.bottomAnchor.pin(equalTo: bottomAnchor).with(priority: .defaultHigh)
        ]
        
        setNeedsUpdateConstraints()
        
        incomingMessageConstraints += [
            messageBubbleView.trailingAnchor.pin(lessThanOrEqualTo: trailingAnchor)
        ]
        
        outgoingMessageConstraints += [
            messageBubbleView.leadingAnchor.pin(greaterThanOrEqualTo: leadingAnchor),
            messageBubbleView.trailingAnchor.pin(equalTo: trailingAnchor)
        ]
    }
    
    open func setupMetadataView() {
        guard messageMetadataView == nil else { return }
        
        let messageMetadataView = uiConfig
            .messageList
            .messageContentSubviews
            .metadataView
            .init()
            .withoutAutoresizingMaskConstraints
        
        self.messageMetadataView = messageMetadataView
        
        addSubview(messageMetadataView)
        
        constraintsToActivate += [
            messageMetadataView.heightAnchor.pin(equalToConstant: 16),
            messageMetadataView.bottomAnchor.pin(equalTo: bottomAnchor)
        ]
        
        setupMessageBubbleView()
        let messageBubbleView = self.messageBubbleView!
        
        incomingMessageConstraints += [
            messageMetadataView.leadingAnchor.pin(equalTo: messageBubbleView.leadingAnchor).with(priority: .defaultHigh)
        ]
        
        outgoingMessageConstraints += [
            messageMetadataView.trailingAnchor.pin(equalTo: messageBubbleView.trailingAnchor).with(priority: .defaultHigh)
        ]
        
        bubbleToMetadataConstraint = messageMetadataView.topAnchor.pin(
            equalToSystemSpacingBelow: messageBubbleView.bottomAnchor,
            multiplier: 1
        )
        
        setNeedsUpdateConstraints()
    }
    
    open func setupAvatarView() {
        guard authorAvatarView == nil else { return }
        
        let authorAvatarView = uiConfig
            .messageList
            .messageContentSubviews
            .authorAvatarView
            .init()
            .withoutAutoresizingMaskConstraints
        self.authorAvatarView = authorAvatarView
        
        addSubview(authorAvatarView)
        
        constraintsToActivate += [
            authorAvatarView.widthAnchor.pin(equalToConstant: 32),
            authorAvatarView.heightAnchor.pin(equalToConstant: 32),
            authorAvatarView.leadingAnchor.pin(equalTo: leadingAnchor),
            authorAvatarView.bottomAnchor.pin(equalTo: bottomAnchor)
        ]
        
        setupMessageBubbleView()
        let messageBubbleView = self.messageBubbleView!
        
        incomingMessageConstraints += [
            messageBubbleView.leadingAnchor.pin(
                equalToSystemSpacingAfter: authorAvatarView.trailingAnchor,
                multiplier: 1
            )
        ]
        
        setNeedsUpdateConstraints()
    }
    
    open func setupReactionsView() {
        guard reactionsBubble == nil else { return }
        
        let reactionsBubble = uiConfig
            .messageList
            .messageReactions
            .reactionsBubbleView
            .init()
            .withoutAutoresizingMaskConstraints
        self.reactionsBubble = reactionsBubble
        
        addSubview(reactionsBubble)
        
        reactionsBubble.isUserInteractionEnabled = false
        
        constraintsToActivate += [
            reactionsBubble.topAnchor.pin(equalTo: topAnchor)
        ]
        
        // this one is ugly: reactions view is part of message content, but is not part of it frame horizontally.
        // In same time we want to prevent reactions view to slip out of screen / cell.
        // We maybe should rethink layout of content view and make reactions part of frame horizontally as well.
        // This will solve superview access hack
        if let superview = self.superview {
            constraintsToActivate += [
                reactionsBubble.trailingAnchor.pin(lessThanOrEqualTo: superview.trailingAnchor),
                reactionsBubble.leadingAnchor.pin(greaterThanOrEqualTo: superview.leadingAnchor)
            ]
        }
        
        setupMessageBubbleView()
        let messageBubbleView = self.messageBubbleView!
        
        incomingMessageConstraints += [
            reactionsBubble.centerXAnchor.pin(equalTo: messageBubbleView.trailingAnchor, constant: 8),
            reactionsBubble.tailLeadingAnchor.pin(equalTo: messageBubbleView.trailingAnchor, constant: -5)
        ]
        
        outgoingMessageConstraints += [
            reactionsBubble.centerXAnchor.pin(equalTo: messageBubbleView.leadingAnchor, constant: -8),
            reactionsBubble.tailTrailingAnchor.pin(equalTo: messageBubbleView.leadingAnchor, constant: 5)
        ]
        
        bubbleToReactionsConstraint = messageBubbleView.topAnchor.pin(
            equalTo: reactionsBubble.centerYAnchor
        )
        
        setNeedsUpdateConstraints()
    }
    
    open func setupThreadArrowView() {
        guard threadArrowView == nil else { return }
        
        setupMessageBubbleView()
        let messageBubbleView = self.messageBubbleView!
        
        let threadArrowView = uiConfig
            .messageList
            .messageContentSubviews
            .threadArrowView
            .init()
            .withoutAutoresizingMaskConstraints
        self.threadArrowView = threadArrowView
        
        addSubview(threadArrowView)
        
        constraintsToActivate += [
            threadArrowView.widthAnchor.pin(equalToConstant: 16),
            threadArrowView.topAnchor.pin(equalTo: messageBubbleView.centerYAnchor)
        ]
        
        incomingMessageConstraints += [
            threadArrowView.leadingAnchor.pin(equalTo: messageBubbleView.leadingAnchor)
        ]
        
        outgoingMessageConstraints += [
            threadArrowView.trailingAnchor.pin(equalTo: messageBubbleView.trailingAnchor)
        ]
        
        setNeedsUpdateConstraints()
    }
    
    open func setupThreadView() {
        guard threadView == nil else { return }
        
        setupMessageBubbleView()
        let messageBubbleView = self.messageBubbleView!
        
        setupThreadArrowView()
        let threadArrowView = self.threadArrowView!
        
        let threadView = uiConfig
            .messageList
            .messageContentSubviews
            .threadInfoView
            .init()
            .withoutAutoresizingMaskConstraints
        self.threadView = threadView
        
        addSubview(threadView)
        
        threadView.addTarget(self, action: #selector(didTapOnThread), for: .touchUpInside)
        
        constraintsToActivate += [
            threadArrowView.bottomAnchor.pin(equalTo: threadView.centerYAnchor),
            threadView.topAnchor.pin(equalToSystemSpacingBelow: messageBubbleView.bottomAnchor, multiplier: 1)
        ]
        
        setupMetadataView()
        let messageMetadataView = self.messageMetadataView!

        incomingMessageIsThreadConstraints = [
            threadView.bottomAnchor.pin(equalTo: bottomAnchor),
            messageMetadataView.leadingAnchor.pin(equalToSystemSpacingAfter: threadView.trailingAnchor, multiplier: 1)
        ]
        
        outgoingMessageIsThreadConstraints = [
            threadView.bottomAnchor.pin(equalTo: bottomAnchor),
            threadView.leadingAnchor.pin(equalToSystemSpacingAfter: messageMetadataView.trailingAnchor, multiplier: 1)
        ]
        
        incomingMessageConstraints += [
            threadView.leadingAnchor.pin(equalTo: threadArrowView.trailingAnchor)
        ]
        
        outgoingMessageConstraints += [
            threadView.trailingAnchor.pin(equalTo: threadArrowView.leadingAnchor)
        ]
        
        setNeedsUpdateConstraints()
    }
    
    open func setupErrorIndicator() {
        guard errorIndicator == nil else { return }
        
        setupMessageBubbleView()
        let messageBubbleView = self.messageBubbleView!
        
        let errorIndicator = uiConfig
            .messageList
            .messageContentSubviews
            .errorIndicator
            .init()
            .withoutAutoresizingMaskConstraints
        self.errorIndicator = errorIndicator
        
        errorIndicator.isVisible = false
        
        addSubview(errorIndicator)
        
        errorIndicator.addTarget(self, action: #selector(didTapOnErrorIndicator), for: .touchUpInside)
        
        errorIndicator.setContentCompressionResistancePriority(.required, for: .horizontal)
        errorIndicator.setContentCompressionResistancePriority(.required, for: .vertical)
        
        constraintsToActivate += [
            errorIndicator.bottomAnchor.pin(equalTo: messageBubbleView.bottomAnchor),
            errorIndicator.trailingAnchor.pin(equalTo: trailingAnchor)
        ]
        
        bubbleToErrorIndicatorConstraint = messageBubbleView.trailingAnchor.pin(
            equalTo: errorIndicator.centerXAnchor
        )
        
        setNeedsUpdateConstraints()
    }
    
    open func setupQuoteView() {
        guard messageQuoteView == nil else { return }
        
        let messageQuoteView = uiConfig
            .messageQuoteView.init()
            .withoutAutoresizingMaskConstraints
        
        self.messageQuoteView = messageQuoteView
        
        addSubview(messageQuoteView)

        self.messageQuoteView?.containerView.isLayoutMarginsRelativeArrangement = false
        self.messageQuoteView?.contentContainerView.backgroundColor = uiConfig.colorPalette.background1

        messageQuoteView.isVisible = false
    }
    
    open func setupLinkPreviewView() {
        guard linkPreviewView == nil else { return }
        
        let linkPreviewView = uiConfig
            .messageList
            .messageContentSubviews
            .linkPreviewView
            .init()
            .withoutAutoresizingMaskConstraints
        self.linkPreviewView = linkPreviewView
        
        addSubview(linkPreviewView)
        
        linkPreviewView.isVisible = false
        
        linkPreviewView.addTarget(self, action: #selector(didTapOnLinkPreview), for: .touchUpInside)
    }
    
    open func setupTextView() {
        guard textView == nil else { return }
        
        let textView = OnlyLinkTappableTextView()
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = uiConfig.font.body
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.translatesAutoresizingMaskIntoConstraints = false
        self.textView = textView
        
        addSubview(textView)
    }
    
    open func setupAttachmentView() {
        guard attachmentsView == nil else { return }
        
        setupMessageBubbleView()
        let messageBubbleView = self.messageBubbleView!
        
        let attachmentsView = uiConfig
            .messageList
            .messageContentSubviews
            .attachmentSubviews
            .attachmentsView
            .init()
            .withoutAutoresizingMaskConstraints
        self.attachmentsView = attachmentsView
        
        // We add `attachmentsView` as a subview to `bubbleView`
        // so it's corners are properly masked
        messageBubbleView.addSubview(attachmentsView)
        
        attachmentsView.isVisible = false
    }
    
    private func getConstraints(for layoutOptions: ChatMessageContentViewLayoutOptions) -> [NSLayoutConstraint] {
        switch layoutOptions {
        case [.attachments]:
            return [
                attachmentsView!.leadingAnchor.pin(equalTo: messageBubbleView!.leadingAnchor),
                attachmentsView!.trailingAnchor.pin(equalTo: messageBubbleView!.trailingAnchor),
                attachmentsView!.topAnchor.pin(equalTo: messageBubbleView!.topAnchor),
                attachmentsView!.bottomAnchor.pin(equalTo: messageBubbleView!.bottomAnchor),
                attachmentsView!.widthAnchor.pin(equalToConstant: UIScreen.main.bounds.width * 0.6)
            ]
        case [.text, .attachments]:
            return [
                attachmentsView!.leadingAnchor.pin(equalTo: messageBubbleView!.leadingAnchor),
                attachmentsView!.trailingAnchor.pin(equalTo: messageBubbleView!.trailingAnchor),
                attachmentsView!.topAnchor.pin(equalTo: messageBubbleView!.topAnchor),
                attachmentsView!.widthAnchor.pin(equalToConstant: UIScreen.main.bounds.width * 0.6),
                
                textView!.leadingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.leadingAnchor),
                textView!.trailingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.trailingAnchor),
                textView!.topAnchor.pin(equalToSystemSpacingBelow: attachmentsView!.bottomAnchor, multiplier: 1),
                textView!.bottomAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.bottomAnchor)
            ]
        case [.attachments, .quotedMessage]:
            return [
                messageQuoteView!.leadingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.leadingAnchor),
                messageQuoteView!.trailingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.trailingAnchor),
                messageQuoteView!.topAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.topAnchor),
                
                attachmentsView!.leadingAnchor.pin(equalTo: messageBubbleView!.leadingAnchor),
                attachmentsView!.trailingAnchor.pin(equalTo: messageBubbleView!.trailingAnchor),
                attachmentsView!.topAnchor.pin(equalToSystemSpacingBelow: messageQuoteView!.bottomAnchor, multiplier: 1),
                attachmentsView!.widthAnchor.pin(equalToConstant: UIScreen.main.bounds.width * 0.6),
                attachmentsView!.bottomAnchor.pin(equalTo: messageBubbleView!.bottomAnchor)
            ]
        case [.text, .attachments, .quotedMessage]:
            return [
                messageQuoteView!.leadingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.leadingAnchor),
                messageQuoteView!.trailingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.trailingAnchor),
                messageQuoteView!.topAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.topAnchor),
                
                attachmentsView!.leadingAnchor.pin(equalTo: messageBubbleView!.leadingAnchor),
                attachmentsView!.trailingAnchor.pin(equalTo: messageBubbleView!.trailingAnchor),
                attachmentsView!.topAnchor.pin(equalToSystemSpacingBelow: messageQuoteView!.bottomAnchor, multiplier: 1),
                attachmentsView!.widthAnchor.pin(equalToConstant: UIScreen.main.bounds.width * 0.6),
                
                textView!.leadingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.leadingAnchor),
                textView!.trailingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.trailingAnchor),
                textView!.topAnchor.pin(equalToSystemSpacingBelow: attachmentsView!.bottomAnchor, multiplier: 1),
                textView!.bottomAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.bottomAnchor)
            ]
        case [.text]:
            return [
                textView!.leadingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.leadingAnchor),
                textView!.trailingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.trailingAnchor),
                textView!.topAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.topAnchor),
                textView!.bottomAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.bottomAnchor)
            ]
        case [.quotedMessage]:
            return [
                messageQuoteView!.leadingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.leadingAnchor),
                messageQuoteView!.trailingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.trailingAnchor),
                messageQuoteView!.topAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.topAnchor),
                messageQuoteView!.bottomAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.bottomAnchor)
            ]
        case [.text, .linkPreview]:
            return [
                textView!.topAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.topAnchor),
                textView!.leadingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.leadingAnchor),
                textView!.trailingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.trailingAnchor),
                
                linkPreviewView!.leadingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.leadingAnchor),
                linkPreviewView!.trailingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.trailingAnchor),
                linkPreviewView!.topAnchor.pin(equalToSystemSpacingBelow: textView!.bottomAnchor, multiplier: 1),
                linkPreviewView!.bottomAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.bottomAnchor),
                linkPreviewView!.widthAnchor.pin(equalToConstant: UIScreen.main.bounds.width * 0.6)
            ]
        // link preview cannot exist without text, we can skip `[.linkPreview]` case
        case [.text, .quotedMessage]:
            return [
                messageQuoteView!.leadingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.leadingAnchor),
                messageQuoteView!.trailingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.trailingAnchor),
                messageQuoteView!.topAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.topAnchor),
                
                textView!.leadingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.leadingAnchor),
                textView!.trailingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.trailingAnchor),
                textView!.topAnchor.pin(equalToSystemSpacingBelow: messageQuoteView!.bottomAnchor, multiplier: 1),
                textView!.bottomAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.bottomAnchor)
            ]
        case [.text, .quotedMessage, .linkPreview]:
            return [
                messageQuoteView!.leadingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.leadingAnchor),
                messageQuoteView!.trailingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.trailingAnchor),
                messageQuoteView!.topAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.topAnchor),
                
                textView!.leadingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.leadingAnchor),
                textView!.trailingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.trailingAnchor),
                textView!.topAnchor.pin(equalToSystemSpacingBelow: messageQuoteView!.bottomAnchor, multiplier: 1),
                
                linkPreviewView!.leadingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.leadingAnchor),
                linkPreviewView!.trailingAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.trailingAnchor),
                linkPreviewView!.topAnchor.pin(equalToSystemSpacingBelow: textView!.bottomAnchor, multiplier: 1),
                linkPreviewView!.bottomAnchor.pin(equalTo: messageBubbleView!.layoutMarginsGuide.bottomAnchor),
                linkPreviewView!.widthAnchor.pin(equalToConstant: UIScreen.main.bounds.width * 0.6)
            ]
        // link preview is not visible when any attachment presented,
        // so we can skip `[.text, .attachments, .quotedMessage, .linkPreview]` case
        // --
        default:
            return []
        }
    }

    // MARK: wip

    open func removeAllDynamicConstraints() {
        constraintsToDeactivate += outgoingMessageConstraints
        constraintsToDeactivate += incomingMessageConstraints
        constraintsToDeactivate += outgoingMessageIsThreadConstraints
        constraintsToDeactivate += incomingMessageIsThreadConstraints

        constraintsToDeactivate += [
            bubbleToReactionsConstraint,
            bubbleToErrorIndicatorConstraint,
            bubbleToMetadataConstraint
        ].compactMap { $0 }

        setNeedsUpdateConstraints()
    }

    public var constraintsToActivate: [NSLayoutConstraint] = []
    public var constraintsToDeactivate: [NSLayoutConstraint] = []
    
    // MARK: - Update family of functions

    override open func updateConstraints() {
        super.updateConstraints()

        defer {
            constraintsToActivate = []
            constraintsToDeactivate = []
        }

        NSLayoutConstraint.deactivate(constraintsToDeactivate)
        NSLayoutConstraint.activate(constraintsToActivate)
    }

    open func updateThreadViewsIfNeeded() {
        guard let message = message else { return /* todo */ }

        let isOutgoing = message.isSentByCurrentUser
        let isPartOfThread = message.isPartOfThread
        
        setupThreadView()
        let threadView = self.threadView!
        
        setupThreadArrowView()
        let threadArrowView = self.threadArrowView!

        threadView.message = message

        threadArrowView.direction = isOutgoing ? .toLeading : .toTrailing

        threadView.isVisible = isPartOfThread
        threadArrowView.isVisible = isPartOfThread
        if isPartOfThread {
            if isOutgoing {
                constraintsToActivate.append(contentsOf: outgoingMessageIsThreadConstraints)
                constraintsToDeactivate.append(contentsOf: incomingMessageIsThreadConstraints)
            } else {
                constraintsToActivate.append(contentsOf: incomingMessageIsThreadConstraints)
                constraintsToDeactivate.append(contentsOf: outgoingMessageIsThreadConstraints)
            }
        } else {
            constraintsToDeactivate.append(contentsOf: outgoingMessageIsThreadConstraints)
            constraintsToDeactivate.append(contentsOf: incomingMessageIsThreadConstraints)
        }
    }

    // todo -> move to the avatar view itself
    open func updateAvatarViewIfNeeded() {
        guard let message = message else { return /* todo */ }
        
        let shouldDisplayAuthorAvatarView = !message.isSentByCurrentUser && message.isLastInGroup
        
        setupAvatarView()
        let authorAvatarView = self.authorAvatarView!
        
        authorAvatarView.isVisible = shouldDisplayAuthorAvatarView
        
        let placeholder = uiConfig.images.userAvatarPlaceholder1
        if let imageURL = message.author.imageURL {
            authorAvatarView.imageView.loadImage(from: imageURL, placeholder: placeholder)
        } else {
            authorAvatarView.imageView.image = placeholder
        }
    }
    
    open func updateReactionsViewIfNeeded() {
        guard let message = message else { return /* todo */ }
        
        let shouldDisplayReactions = message.deletedAt == nil && !message.reactionScores.isEmpty
        
        setupReactionsView()
        let reactionsBubble = self.reactionsBubble!
        
        reactionsBubble.isVisible = shouldDisplayReactions
        
        let userReactionIDs = Set(message.currentUserReactions.map(\.type))
        
        let isOutgoing = message.isSentByCurrentUser
        
        reactionsBubble.content = .init(
            style: isOutgoing ? .smallOutgoing : .smallIncoming,
            reactions: message.message.reactionScores.keys
                .sorted { $0.rawValue < $1.rawValue }
                .map { .init(type: $0, isChosenByCurrentUser: userReactionIDs.contains($0)) },
            didTapOnReaction: { _ in }
        )
        
        if shouldDisplayReactions {
            constraintsToActivate.append(bubbleToReactionsConstraint!)
        } else {
            constraintsToDeactivate.append(bubbleToReactionsConstraint!)
        }
    }
    
    open func updateBubbleViewIfNeeded() {
        guard let message = message else { return /* todo */ }
        
        setupMessageBubbleView()
        setupMetadataView()
        setupErrorIndicator()
        let messageBubbleView = self.messageBubbleView!
        
        messageBubbleView.message = message
        
        if message.isLastInGroup {
            constraintsToActivate.append(bubbleToMetadataConstraint!)
        } else {
            constraintsToDeactivate.append(bubbleToMetadataConstraint!)
        }
        
        if message.lastActionFailed {
            constraintsToActivate.append(bubbleToErrorIndicatorConstraint!)
        } else {
            constraintsToDeactivate.append(bubbleToErrorIndicatorConstraint!)
        }
        
        if message.type == .ephemeral {
            messageBubbleView.backgroundColor = uiConfig.colorPalette.popoverBackground
        } else if message.layoutOptions.contains(.linkPreview) {
            messageBubbleView.backgroundColor = uiConfig.colorPalette.highlightedAccentBackground1
        } else {
            messageBubbleView.backgroundColor = message.isSentByCurrentUser == true ?
                uiConfig.colorPalette.background2 :
                uiConfig.colorPalette.popoverBackground
        }
    }
    
    open func updateMetadataViewIfNeeded() {
        let shouldDisplayMetadataView = message?.isLastInGroup ?? false
        
        setupMetadataView()
        let messageMetadataView = self.messageMetadataView!
        
        messageMetadataView.message = message

        messageMetadataView.isVisible = shouldDisplayMetadataView
    }
    
    open func updateQuotedMessageViewIfNeeded() {
        guard let message = message else { return /* todo */ }
        
        let shouldDisplayQuotedMessage = message.layoutOptions.contains(.quotedMessage)
        
        setupQuoteView()
        let quotedMessageView = messageQuoteView!
        quotedMessageView.content = .init(
            message: message.quotedMessage,
            avatarAlignment: message.isSentByCurrentUser ? .right : .left
        )
        quotedMessageView.isVisible = shouldDisplayQuotedMessage
    }
    
    open func updateErrorIndicatorIfNeeded() {
        let shouldDisplayErrorIndicator = message?.lastActionFailed ?? false
        
        setupErrorIndicator()
        let errorIndicator = self.errorIndicator!
        
        errorIndicator.isVisible = shouldDisplayErrorIndicator
    }
    
    open func updateLinkPreviewViewIfNeeded() {
        guard let message = message else { return /* todo */ }
        
        let shouldDisplayLinkPreviewView = message.layoutOptions.contains(.linkPreview)
        
        setupLinkPreviewView()
        let linkPreviewView = self.linkPreviewView!
        
        linkPreviewView.content = message.attachments.first { $0.type.isLink } as? ChatMessageDefaultAttachment
        
        linkPreviewView.isVisible = shouldDisplayLinkPreviewView
    }
    
    open func updateAttachmentsViewIfNeeded() {
        guard let message = message else { return /* todo */ }
        
        let shouldDisplayAttachmentsView = message.layoutOptions.contains(.attachments)
        
        setupAttachmentView()
        let attachmentsView = self.attachmentsView!
        
        attachmentsView.content = .init(
            attachments: message.attachments.compactMap { $0 as? ChatMessageDefaultAttachment },
            didTapOnAttachment: message.didTapOnAttachment,
            didTapOnAttachmentAction: message.didTapOnAttachmentAction
        )
        
        attachmentsView.isVisible = shouldDisplayAttachmentsView
    }
    
    open func updateTextViewIfNeeded() {
        guard let message = message else { return /* todo */ }
        
        setupTextView()
        let textView = self.textView!
        
        let font: UIFont = uiConfig.font.body
        textView.attributedText = .init(string: message.textContent, attributes: [
            .foregroundColor: message.deletedAt == nil ? uiConfig.colorPalette.text : uiConfig.colorPalette.subtitleText,
            .font: message.deletedAt == nil ? font : font.italic
        ])
        
        textView.isVisible = message.layoutOptions.contains(.text)
    }
    
    open func updateMessagePositionIfNeeded() { // TODO: find a better name
        if message?.isSentByCurrentUser ?? false {
            constraintsToActivate.append(contentsOf: outgoingMessageConstraints)
            constraintsToDeactivate.append(contentsOf: incomingMessageConstraints)
        } else {
            constraintsToActivate.append(contentsOf: incomingMessageConstraints)
            constraintsToDeactivate.append(contentsOf: outgoingMessageConstraints)
        }
    }

    // ======

    override open func updateContent() {
        // When message cell is about to be reused, it sets `nil` for message value.
        // That means we need to remove all dynamic constraints to prevent layout warnings.
        guard let message = self.message else {
            removeAllDynamicConstraints()
            return
        }

        // Base views in the message
        updateBubbleViewIfNeeded()
        updateMetadataViewIfNeeded()
        updateReactionsViewIfNeeded()
        updateThreadViewsIfNeeded()
        updateAvatarViewIfNeeded()
        updateMessagePositionIfNeeded()
        updateErrorIndicatorIfNeeded()

        // Additional views
        updateTextViewIfNeeded()
        updateQuotedMessageViewIfNeeded()
        updateLinkPreviewViewIfNeeded()
        updateAttachmentsViewIfNeeded()
        
        // Necessary constraints
        if !didSetUpConstraints {
            constraintsToActivate.append(contentsOf: getConstraints(for: message.layoutOptions))
            didSetUpConstraints = true
        }

        setNeedsUpdateConstraints()
    }

    // MARK: - Actions

    @objc open func didTapOnErrorIndicator() {
        onErrorIndicatorTap(message)
    }

    @objc func didTapOnThread() {
        onThreadTap(message)
    }
    
    @objc func didTapOnLinkPreview() {
        guard let linkPreviewView = linkPreviewView else { return } // todo
        onLinkTap(linkPreviewView.content)
    }
}

public struct ChatMessageContentViewLayoutOptions: OptionSet, Hashable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let text = Self(rawValue: 1 << 0)
    public static let attachments = Self(rawValue: 1 << 1)
    public static let quotedMessage = Self(rawValue: 1 << 2)
    public static let linkPreview = Self(rawValue: 1 << 3)
    
    public static let all: Self = [.text, .attachments, .quotedMessage, .linkPreview]
}

// MARK: - Extensions

extension _ChatMessage {
    var textContent: String {
        guard type != .ephemeral else {
            return ""
        }

        guard deletedAt == nil else {
            return L10n.Message.deletedMessagePlaceholder
        }

        return text
    }
}

extension _ChatMessageGroupPart {
    var layoutOptions: ChatMessageContentViewLayoutOptions {
        guard message.deletedAt == nil else {
            return [.text]
        }
        
        var options: ChatMessageContentViewLayoutOptions = []
        
        if !message.textContent.isEmpty {
            options.insert(.text)
        }
        
        if quotedMessage != nil {
            options.insert(.quotedMessage)
        }
        
        if message.attachments.contains(where: { $0.type == .image || $0.type == .giphy || $0.type == .file }) {
            options.insert(.attachments)
        } else if message.attachments.contains(where: { $0.type.isLink }) {
            // link preview is visible only when no other attachments available
            options.insert(.linkPreview)
        }
        
        return options
    }
}
