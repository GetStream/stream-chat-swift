//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageContentView<ExtraData: UIExtraDataTypes>: View, UIConfigProvider {
    public var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContent() }
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

    private var incomingMessageGroupPartConstraints: [NSLayoutConstraint] = []
    private var incomingMessageGroupFooterConstraints: [NSLayoutConstraint] = []
    private var outgoingMessageGroupPartConstraints: [NSLayoutConstraint] = []
    private var outgoingMessageGroupFooterConstraints: [NSLayoutConstraint] = []

    // MARK: - Overrides

    override open func setUpLayout() {
        addSubview(messageBubbleView)
        addSubview(messageMetadataView)
        addSubview(authorAvatarView)
        addSubview(messageReactionsView)

        incomingMessageGroupPartConstraints = [
            messageBubbleView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            messageBubbleView.trailingAnchor.constraint(equalTo: trailingAnchor),
            messageBubbleView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            messageReactionsView.topAnchor.constraint(equalTo: topAnchor),
            messageReactionsView.bottomAnchor.constraint(equalTo: messageBubbleView.topAnchor),
            messageReactionsView.centerXAnchor.constraint(equalTo: messageBubbleView.trailingAnchor),
            messageReactionsView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor)
        ]

        incomingMessageGroupFooterConstraints = [
            authorAvatarView.widthAnchor.constraint(equalToConstant: 32),
            authorAvatarView.heightAnchor.constraint(equalToConstant: 32),
            authorAvatarView.leadingAnchor.constraint(equalTo: leadingAnchor),
            authorAvatarView.bottomAnchor.constraint(equalTo: bottomAnchor),

            messageBubbleView.leadingAnchor.constraint(equalToSystemSpacingAfter: authorAvatarView.trailingAnchor, multiplier: 1),
            messageBubbleView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            messageMetadataView.topAnchor.constraint(equalToSystemSpacingBelow: messageBubbleView.bottomAnchor, multiplier: 1),
            messageMetadataView.leadingAnchor.constraint(equalTo: messageBubbleView.leadingAnchor),
            messageMetadataView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            messageReactionsView.topAnchor.constraint(equalTo: topAnchor),
            messageReactionsView.bottomAnchor.constraint(equalTo: messageBubbleView.topAnchor),
            messageReactionsView.centerXAnchor.constraint(equalTo: messageBubbleView.trailingAnchor),
            messageReactionsView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor)
        ]

        outgoingMessageGroupPartConstraints = [
            messageBubbleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            messageBubbleView.trailingAnchor.constraint(equalTo: trailingAnchor),
            messageBubbleView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            messageReactionsView.topAnchor.constraint(equalTo: topAnchor),
            messageReactionsView.bottomAnchor.constraint(equalTo: messageBubbleView.topAnchor),
            messageReactionsView.centerXAnchor.constraint(equalTo: messageBubbleView.leadingAnchor),
            messageReactionsView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        ]

        outgoingMessageGroupFooterConstraints = [
            messageBubbleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            messageBubbleView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            messageMetadataView.topAnchor.constraint(equalToSystemSpacingBelow: messageBubbleView.bottomAnchor, multiplier: 1),
            messageMetadataView.trailingAnchor.constraint(equalTo: trailingAnchor),
            messageMetadataView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            messageReactionsView.topAnchor.constraint(equalTo: topAnchor),
            messageReactionsView.bottomAnchor.constraint(equalTo: messageBubbleView.topAnchor),
            messageReactionsView.centerXAnchor.constraint(equalTo: messageBubbleView.leadingAnchor),
            messageReactionsView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        ]
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

        authorAvatarView.isHidden = message?.isSentByCurrentUser == true || message?.isLastInGroup == false
        messageMetadataView.isHidden = message?.isLastInGroup == false
        activateNecessaryConstraints()
    }

    // MARK: - Private
    
    private func activateNecessaryConstraints() {
        let constraintsToDeactivate: [NSLayoutConstraint]
        let constraintsToActivate: [NSLayoutConstraint]

        switch (message?.isSentByCurrentUser, message?.isLastInGroup) {
        case (true, true):
            constraintsToDeactivate =
                outgoingMessageGroupPartConstraints +
                incomingMessageGroupPartConstraints +
                incomingMessageGroupFooterConstraints
            constraintsToActivate = outgoingMessageGroupFooterConstraints
        case (true, false):
            constraintsToDeactivate =
                outgoingMessageGroupFooterConstraints +
                incomingMessageGroupPartConstraints +
                incomingMessageGroupFooterConstraints
            constraintsToActivate = outgoingMessageGroupPartConstraints
        case (false, true):
            constraintsToDeactivate =
                outgoingMessageGroupPartConstraints +
                outgoingMessageGroupFooterConstraints +
                incomingMessageGroupPartConstraints
            constraintsToActivate = incomingMessageGroupFooterConstraints
        case (false, false):
            constraintsToDeactivate =
                outgoingMessageGroupPartConstraints +
                outgoingMessageGroupFooterConstraints +
                incomingMessageGroupFooterConstraints
            constraintsToActivate = incomingMessageGroupPartConstraints
        default:
            constraintsToDeactivate =
                incomingMessageGroupPartConstraints +
                incomingMessageGroupFooterConstraints +
                outgoingMessageGroupPartConstraints +
                outgoingMessageGroupFooterConstraints
            constraintsToActivate = []
        }
        
        constraintsToDeactivate.forEach { $0.isActive = false }
        constraintsToActivate.forEach { $0.isActive = true }
    }
}
