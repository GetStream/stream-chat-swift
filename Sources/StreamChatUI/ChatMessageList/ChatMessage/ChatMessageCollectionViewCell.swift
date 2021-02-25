//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit


public class TextOnlyContent<ExtraData: ExtraDataTypes>: _ChatMessageContentView<ExtraData> {
    override open func updateContent() {
        // When message cell is about to be reused, it sets `nil` for message value.
        // That means we need to remove all dynamic constraints to prevent layout warnings.
        guard let message = self.message else {
            removeAllDynamicConstraints()
            return
        }

        let isOutgoing = message.isSentByCurrentUser
        let isPartOfThread = message.isPartOfThread

        messageBubbleView.message = message
        messageMetadataView.message = message

        let userReactionIDs = Set(message.currentUserReactions.map(\.type))

        reactionsBubble.content = .init(
            style: isOutgoing ? .smallOutgoing : .smallIncoming,
            reactions: message.message.reactionScores.keys
                .sorted { $0.rawValue < $1.rawValue }
                .map { .init(type: $0, isChosenByCurrentUser: userReactionIDs.contains($0)) },
            didTapOnReaction: { _ in }
        )

        updateThreadViews()
        updateAvatarView()

        if isOutgoing {
            constraintsToActivate.append(contentsOf: outgoingMessageConstraints)
            constraintsToDeactivate.append(contentsOf: incomingMessageConstraints)
        } else {
            constraintsToActivate.append(contentsOf: incomingMessageConstraints)
            constraintsToDeactivate.append(contentsOf: outgoingMessageConstraints)
        }

        if message.deletedAt == nil, !message.reactionScores.isEmpty {
            constraintsToActivate.append(bubbleToReactionsConstraint!)
        } else {
            constraintsToDeactivate.append(bubbleToReactionsConstraint!)
        }

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

        constraintsToActivate += [
            textView.leadingAnchor.pin(equalTo: messageBubbleView.layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.pin(equalTo: messageBubbleView.layoutMarginsGuide.trailingAnchor),
            textView.topAnchor.pin(equalTo: messageBubbleView.layoutMarginsGuide.topAnchor),
            textView.bottomAnchor.pin(equalTo: messageBubbleView.layoutMarginsGuide.bottomAnchor)
        ]

//        NSLayoutConstraint.deactivate(constraintsToDeactivate)
//        NSLayoutConstraint.activate(constraintsToActivate)

        authorAvatarView.isVisible = !isOutgoing && message.isLastInGroup
        messageMetadataView.isVisible = bubbleToMetadataConstraint?.isActive ?? false
        reactionsBubble.isVisible = bubbleToReactionsConstraint?.isActive ?? false
        errorIndicator.isVisible = message.lastActionFailed

        // --


//
//
//        let layoutOptions = message.layoutOptions
//
//        quotedMessageView.isParentMessageSentByCurrentUser = message.isSentByCurrentUser
//        quotedMessageView.message = message.quotedMessage
        quotedMessageView.isVisible = false
////
        let font: UIFont = uiConfig.font.body
        textView.attributedText = .init(string: message.textContent, attributes: [
            .foregroundColor: message.deletedAt == nil ? uiConfig.colorPalette.text : uiConfig.colorPalette.subtitleText,
            .font: message.deletedAt == nil ? font : font.italic
        ])
        textView.isVisible = true
//
//        if message.type == .ephemeral {
//            messageBubbleView.backgroundColor = uiConfig.colorPalette.popoverBackground
//        } else if layoutOptions.contains(.linkPreview) {
//            messageBubbleView.backgroundColor = uiConfig.colorPalette.highlightedAccentBackground1
//        } else {
//            messageBubbleView.backgroundColor = message.isSentByCurrentUser == true ?
//                uiConfig.colorPalette.background2 :
//                uiConfig.colorPalette.popoverBackground
//        }
//
//        linkPreviewView.content = message.attachments.first { $0.type.isLink } as? ChatMessageDefaultAttachment
//
//        linkPreviewView.isVisible = layoutOptions.contains(.linkPreview)
//
//        attachmentsView.content = .init(
//            attachments: message.attachments.compactMap { $0 as? ChatMessageDefaultAttachment },
//            didTapOnAttachment: message.didTapOnAttachment,
//            didTapOnAttachmentAction: message.didTapOnAttachmentAction
//        )
//
//        attachmentsView.isVisible = layoutOptions.contains(.attachments)
//
//        layoutConstraints.values.flatMap { $0 }.forEach { $0.isActive = false }
//        layoutConstraints[layoutOptions]?.forEach { $0.isActive = true }

        // --

        setNeedsUpdateConstraints()
    }
}


open class TextOnlyCell<ExtraData: ExtraDataTypes>: _СhatMessageCollectionViewCell<ExtraData> {
    override public static var messageViewClass: _ChatMessageContentView<ExtraData>.Type { TextOnlyContent<ExtraData>.self }
}


public typealias СhatMessageCollectionViewCell = _СhatMessageCollectionViewCell<NoExtraData>

open class _СhatMessageCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell, UIConfigProvider {
    // MARK: - Reuse identifiers

    class var reuseId: String { String(describing: self) + String(describing: Self.messageContentViewClass) }
    
    public static var incomingMessage2ReuseId: String { "incoming_2_\(reuseId)" }
    public static var incomingMessage3ReuseId: String { "incoming_3_\(reuseId)" }
    public static var incomingMessage6ReuseId: String { "incoming_6_\(reuseId)" }
    public static var incomingMessage7ReuseId: String { "incoming_7_\(reuseId)" }
    public static var incomingMessage1ReuseId: String { "incoming_1_\(reuseId)" }
    public static var incomingMessage4ReuseId: String { "incoming_4_\(reuseId)" }
    public static var incomingMessage9ReuseId: String { "incoming_9_\(reuseId)" }
    public static var incomingMessage5ReuseId: String { "incoming_5_\(reuseId)" }
    public static var incomingMessage13ReuseId: String { "incoming_13_\(reuseId)" }
    
    public static var outgoingMessage2ReuseId: String { "outgoing_2_\(reuseId)" }
    public static var outgoingMessage3ReuseId: String { "outgoing_3_\(reuseId)" }
    public static var outgoingMessage6ReuseId: String { "outgoing_6_\(reuseId)" }
    public static var outgoingMessage7ReuseId: String { "outgoing_7_\(reuseId)" }
    public static var outgoingMessage1ReuseId: String { "outgoing_1_\(reuseId)" }
    public static var outgoingMessage4ReuseId: String { "outgoing_4_\(reuseId)" }
    public static var outgoingMessage9ReuseId: String { "outgoing_9_\(reuseId)" }
    public static var outgoingMessage5ReuseId: String { "outgoing_5_\(reuseId)" }
    public static var outgoingMessage13ReuseId: String { "outgoing_13_\(reuseId)" }
    
    // MARK: - Properties

    public var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    open class var messageContentViewClass: _ChatMessageContentView<ExtraData>.Type { _ChatMessageContentView<ExtraData>.self }

    public private(set) lazy var messageView: _ChatMessageContentView<ExtraData> = Self.messageContentViewClass.init()
        .withoutAutoresizingMaskConstraints
    
    private var messageViewLeadingConstraint: NSLayoutConstraint?
    private var messageViewTrailingConstraint: NSLayoutConstraint?

    private var hasCompletedStreamSetup = false

    // MARK: - Lifecycle

    override open func setUpLayout() {
        contentView.addSubview(messageView)

        NSLayoutConstraint.activate([
            messageView.topAnchor.pin(equalTo: contentView.topAnchor),
            messageView.bottomAnchor.pin(equalTo: contentView.bottomAnchor),
            messageView.widthAnchor.pin(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75)
        ])
    }

    override open func updateContent() {
        messageView.message = message

        switch message?.isSentByCurrentUser {
        case true?:
            assert(messageViewLeadingConstraint == nil, "The cell was already used for incoming message")
            if messageViewTrailingConstraint == nil {
                messageViewTrailingConstraint = messageView.trailingAnchor
                    .pin(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
                messageViewTrailingConstraint!.isActive = true
            }

        case false?:
            assert(messageViewTrailingConstraint == nil, "The cell was already used for outgoing message")
            if messageViewLeadingConstraint == nil {
                messageViewLeadingConstraint = messageView.leadingAnchor
                    .pin(equalTo: contentView.layoutMarginsGuide.leadingAnchor)
                messageViewLeadingConstraint!.isActive = true
            }

        case nil:
            break
        }
    }

    // MARK: - Overrides

    override open func prepareForReuse() {
        super.prepareForReuse()

        message = nil
    }

    override open func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        let preferredAttributes = super.preferredLayoutAttributesFitting(layoutAttributes)

        let targetSize = CGSize(
            width: layoutAttributes.frame.width,
            height: UIView.layoutFittingCompressedSize.height
        )

        contentView.updateConstraintsIfNeeded()

        preferredAttributes.frame.size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        return preferredAttributes
    }
}
