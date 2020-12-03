//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatRepliedMessageContentView<ExtraData: UIExtraDataTypes>: View {
    struct Layout {
        let messageBubble: CGRect?
        let messageBubbleLayout: ChatMessageBubbleView<ExtraData>.Layout?
        let authorAvatar: CGRect?
        let loading: CGRect?
    }

    var layout: Layout? {
        didSet { setNeedsLayout() }
    }

    public var message: _ChatMessage<ExtraData>? {
        didSet { updateContent() }
    }

    // MARK: - Subviews

    public private(set) lazy var messageBubbleView = ChatMessageBubbleView<ExtraData>(showRepliedMessage: false)

    public private(set) lazy var authorAvatarView = AvatarView()

    public private(set) lazy var loadingView = LoadingView()

    // MARK: - Overrides

    override open func layoutSubviews() {
        super.layoutSubviews()
        guard let layout = layout else { return }

        messageBubbleView.isHidden = layout.messageBubble == nil
        if let frame = layout.messageBubble {
            messageBubbleView.frame = frame
        }
        messageBubbleView.layout = layout.messageBubbleLayout

        authorAvatarView.isHidden = layout.authorAvatar == nil
        if let frame = layout.authorAvatar {
            authorAvatarView.frame = frame
        }

        loadingView.isHidden = layout.loading == nil
        if let frame = layout.loading {
            loadingView.frame = frame
        }
    }

    override open func setUpLayout() {
        addSubview(authorAvatarView)
        addSubview(messageBubbleView)
        addSubview(loadingView)
    }

    override open func updateContent() {
        messageBubbleView.message = message.flatMap {
            .init(message: $0, parentMessageState: nil, isLastInGroup: true)
        }

        let placeholder = UIImage(named: "pattern1", in: .streamChatUI)
        if let imageURL = message?.author.imageURL {
            authorAvatarView.imageView.setImage(from: imageURL, placeholder: placeholder)
        } else {
            authorAvatarView.imageView.image = placeholder
        }

        loadingView.isLoading = message == nil
    }
}

extension ChatRepliedMessageContentView {
    open class LoadingView: View {
        public var isLoading: Bool = true {
            didSet {
                updateContent()
            }
        }

        // MARK: - Overrides

        override open var intrinsicContentSize: CGSize {
            .init(
                width: UIView.noIntrinsicMetric,
                height: 60
            )
        }

        // MARK: - Subviews

        public private(set) lazy var activityIndicator: UIActivityIndicatorView = {
            let indicator = UIActivityIndicatorView()
            indicator.hidesWhenStopped = true
            return indicator
        }()

        // MARK: - Overrides

        override open func setUpLayout() {
            addSubview(activityIndicator)
            activityIndicator.pin(anchors: [.centerX, .centerY], to: self)
        }

        override open func updateContent() {
            if isLoading {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }

        override public func defaultAppearance() {
            activityIndicator.style = .gray
        }
    }
}

class ChatRepliedMessageContentViewLayoutManager<ExtraData: UIExtraDataTypes> {
    let bubbleSizer = ChatMessageBubbleViewLayoutManager<ExtraData>()

    func heightForView(with data: _ChatMessage<ExtraData>?, limitedBy width: CGFloat) -> CGFloat {
        sizeForView(with: data, limitedBy: width).height
    }

    func sizeForView(with data: _ChatMessage<ExtraData>?, limitedBy width: CGFloat) -> CGSize {
        guard let message = data else {
            return CGSize(width: width, height: 60)
        }
        let spacing: CGFloat = 8
        let avatarSize = CGSize(width: 24, height: 24)
        let group = _ChatMessageGroupPart(message: message, parentMessageState: nil, isLastInGroup: true)
        let bubbleSize = bubbleSizer.sizeForView(with: group, limitedBy: width - avatarSize.width - spacing)
        let height = max(avatarSize.height, bubbleSize.height)
        return CGSize(width: avatarSize.width + spacing + bubbleSize.width, height: height)
    }

    func layoutForView(
        with data: _ChatMessage<ExtraData>?,
        of size: CGSize
    ) -> ChatRepliedMessageContentView<ExtraData>.Layout {
        let width = size.width
        let height = size.height
        guard let message = data else {
            let loadingFrame = CGRect(x: (width - 60) / 2, y: 0, width: 60, height: 60)
            return ChatRepliedMessageContentView.Layout(
                messageBubble: nil,
                messageBubbleLayout: nil,
                authorAvatar: nil,
                loading: loadingFrame
            )
        }
        let spacing: CGFloat = 8
        let avatarSize = CGSize(width: 24, height: 24)
        let isSentByCurrentUser = message.isSentByCurrentUser
        let avatarOffsetX = isSentByCurrentUser
            ? width - avatarSize.width
            : 0

        let group = _ChatMessageGroupPart(message: message, parentMessageState: nil, isLastInGroup: true)
        let bubbleSize = bubbleSizer.sizeForView(with: group, limitedBy: width - avatarSize.width - spacing)

        let avatarFrame = CGRect(origin: CGPoint(x: avatarOffsetX, y: height - avatarSize.height), size: avatarSize)

        let bubbleOffsetX = isSentByCurrentUser
            ? 0
            : avatarFrame.maxX + spacing
        let bubbleFrame = CGRect(
            origin: CGPoint(x: bubbleOffsetX, y: max(0, height - bubbleSize.height)),
            size: bubbleSize
        )

        return ChatRepliedMessageContentView.Layout(
            messageBubble: bubbleFrame,
            messageBubbleLayout: bubbleSizer.layoutForView(with: group, of: bubbleSize),
            authorAvatar: avatarFrame,
            loading: nil
        )
    }
}
