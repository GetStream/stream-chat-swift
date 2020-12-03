//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageContentView<ExtraData: UIExtraDataTypes>: View, UIConfigProvider {
    struct Layout {
        let messageBubble: CGRect?
        let messageBubbleLayout: ChatMessageBubbleView<ExtraData>.Layout?
        let messageMetadata: CGRect?
        let messageMetadataLayout: ChatMessageMetadataView<ExtraData>.Layout?
        let authorAvatar: CGRect?
        let reactions: CGRect?
    }

    var layout: Layout? {
        didSet { setNeedsLayout() }
    }

    public var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContent() }
    }

    // MARK: - Subviews

    public private(set) lazy var messageBubbleView = uiConfig
        .messageList
        .messageContentSubviews
        .bubbleView
        .init(showRepliedMessage: true)

    public private(set) lazy var messageMetadataView = uiConfig
        .messageList
        .messageContentSubviews
        .metadataView
        .init()
    
    public private(set) lazy var authorAvatarView = uiConfig
        .messageList
        .messageContentSubviews
        .authorAvatarView
        .init()

    let messageReactionsView = ChatMessageReactionsView().withoutAutoresizingMaskConstraints

    // MARK: - Overrides

    override open func setUpLayout() {
        addSubview(messageBubbleView)
        addSubview(messageMetadataView)
        addSubview(authorAvatarView)
        addSubview(messageReactionsView)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        messageBubbleView.isHidden = layout?.messageBubble == nil
        if let frame = layout?.messageBubble {
            messageBubbleView.frame = frame
        }
        messageBubbleView.layout = layout?.messageBubbleLayout

        messageMetadataView.isHidden = layout?.messageMetadata == nil
        if let frame = layout?.messageMetadata {
            messageMetadataView.frame = frame
        }
        messageMetadataView.layout = layout?.messageMetadataLayout

        authorAvatarView.isHidden = layout?.authorAvatar == nil
        if let frame = layout?.authorAvatar {
            authorAvatarView.frame = frame
        }

        messageReactionsView.isHidden = layout?.reactions == nil
        if let frame = layout?.reactions {
            messageReactionsView.frame = frame
        }
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
    }
}

extension ChatMessageContentView {
    class LayoutProvider: ConfiguredLayoutProvider<ExtraData> {
        lazy var bubbleSizer = ChatMessageBubbleView<ExtraData>.LayoutProvider(parent: self)
        lazy var metadataSizer = ChatMessageMetadataView<ExtraData>.LayoutProvider(parent: self)
        private let reactions = ChatMessageReactionsView()

        func heightForView(with data: _ChatMessageGroupPart<ExtraData>, limitedBy width: CGFloat) -> CGFloat {
            sizeForView(with: data, limitedBy: width).height
        }

        func sizeForView(with data: _ChatMessageGroupPart<ExtraData>, limitedBy width: CGFloat) -> CGSize {
            let margins = uiConfig.messageList.defaultMargins
            let isSentByCurrentUser = data.isSentByCurrentUser
            let avatarSize = isSentByCurrentUser ? .zero : CGSize(width: 32, height: 32)
            let reactionsSize = sizeForReactions(with: data, limitedBy: width)
            let bubbleLeading: CGFloat = isSentByCurrentUser ? 0 : (avatarSize.width + margins)

            var height = reactionsSize?.height ?? 0

            let bubbleSize = bubbleSizer.sizeForView(with: data, limitedBy: width - bubbleLeading)
            var nonAvatarWidth = bubbleSize.width
            height += bubbleSize.height

            let metadataSize = metadataSizer.sizeForView(with: data, limitedBy: width - bubbleLeading)
            if data.isLastInGroup {
                height += margins
                height += metadataSize.height
                nonAvatarWidth = max(nonAvatarWidth, metadataSize.width)
            }

            height = max(avatarSize.height, height)
            let width = bubbleLeading + nonAvatarWidth
            return CGSize(width: width, height: height)
        }

        func layoutForView(
            with data: _ChatMessageGroupPart<ExtraData>,
            of size: CGSize
        ) -> Layout {
            let width = size.width
            let height = size.height

            let isSentByCurrentUser = data.isSentByCurrentUser
            let isLastInGroup = data.isLastInGroup
            let spacing: CGFloat = uiConfig.messageList.defaultMargins

            // sizes
            let avatarSize = isSentByCurrentUser ? .zero : CGSize(width: 32, height: 32)
            let reactionsSize = sizeForReactions(with: data, limitedBy: width)
            let avatarMaxX = isSentByCurrentUser ? 0 : avatarSize.width + spacing
            let bubbleSize = bubbleSizer.sizeForView(with: data, limitedBy: width - avatarMaxX)
            let metadataSize = metadataSizer.sizeForView(with: data, limitedBy: width - avatarMaxX)

            // frames
            let avatarFrame: CGRect? = {
                guard !isSentByCurrentUser, isLastInGroup else { return nil }
                return CGRect(origin: CGPoint(x: 0, y: height - avatarSize.height), size: avatarSize)
            }()

            let reactionsBottom: CGFloat = reactionsSize?.height ?? 0
            let bubbleLeading = isSentByCurrentUser
                ? width - bubbleSize.width
                : avatarMaxX
            let bubbleFrame = CGRect(origin: CGPoint(x: bubbleLeading, y: reactionsBottom), size: bubbleSize)

            let reactionFrame: CGRect? = reactionsSize.map { size in
                let originX: CGFloat = isSentByCurrentUser
                    ? min(bubbleFrame.minX - size.width / 2, width - size.width)
                    : max(bubbleFrame.maxX - size.width / 2, 0)
                return CGRect(origin: CGPoint(x: originX, y: 0), size: size)
            }

            let metadataFrame: CGRect? = {
                guard isLastInGroup else { return nil }
                let originX = isSentByCurrentUser
                    ? width - metadataSize.width
                    : bubbleLeading
                return CGRect(
                    origin: CGPoint(x: originX, y: bubbleFrame.maxY + 8),
                    size: metadataSize
                )
            }()

            return Layout(
                messageBubble: bubbleFrame,
                messageBubbleLayout: bubbleSizer.layoutForView(with: data, of: bubbleSize),
                messageMetadata: metadataFrame,
                messageMetadataLayout: metadataFrame == nil ? nil : metadataSizer.layoutForView(with: data, of: metadataSize),
                authorAvatar: avatarFrame,
                reactions: reactionFrame
            )
        }

        func sizeForReactions(with data: _ChatMessageGroupPart<ExtraData>, limitedBy width: CGFloat) -> CGSize? {
            guard !data.message.reactionScores.isEmpty else { return nil }
            reactions.style = data.isSentByCurrentUser ? .smallOutgoing : .smallIncoming
            reactions.reload(from: data.message)
            return reactions.systemLayoutSizeFitting(CGSize(width: width, height: 300))
        }
    }
}
