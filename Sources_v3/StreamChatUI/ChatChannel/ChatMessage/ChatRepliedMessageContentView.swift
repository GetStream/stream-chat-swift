//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatRepliedMessageContentView<ExtraData: ExtraDataTypes>: View {
    public var message: _ChatMessage<ExtraData>? {
        didSet { updateContent() }
    }

    // MARK: - Subviews

    public private(set) lazy var messageBubbleView = ChatMessageBubbleView<ExtraData>(showRepliedMessage: false)
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var authorAvatarView = AvatarView()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var loadingView = LoadingView()

    private var avatarOnTheLeftConstraints: [NSLayoutConstraint] = []
    private var avatarOnTheRightConstraints: [NSLayoutConstraint] = []

    // MARK: - Overrides

    override open func setUpLayout() {
        addSubview(authorAvatarView)
        addSubview(messageBubbleView)
        embed(loadingView)

        avatarOnTheLeftConstraints = [
            authorAvatarView.widthAnchor.pin(equalToConstant: 24),
            authorAvatarView.heightAnchor.pin(equalToConstant: 24),
            authorAvatarView.leadingAnchor.pin(equalTo: leadingAnchor),
            authorAvatarView.bottomAnchor.pin(equalTo: bottomAnchor),
            
            messageBubbleView.topAnchor.pin(equalTo: topAnchor),
            messageBubbleView.leadingAnchor.pin(equalToSystemSpacingAfter: authorAvatarView.trailingAnchor, multiplier: 1),
            messageBubbleView.trailingAnchor.pin(equalTo: trailingAnchor),
            messageBubbleView.bottomAnchor.pin(equalTo: bottomAnchor)
        ]

        avatarOnTheRightConstraints = [
            messageBubbleView.topAnchor.pin(equalTo: topAnchor),
            messageBubbleView.leadingAnchor.pin(equalTo: leadingAnchor),
            messageBubbleView.bottomAnchor.pin(equalTo: bottomAnchor),
            
            authorAvatarView.widthAnchor.pin(equalToConstant: 24),
            authorAvatarView.heightAnchor.pin(equalToConstant: 24),
            authorAvatarView.trailingAnchor.pin(equalTo: trailingAnchor),
            authorAvatarView.bottomAnchor.pin(equalTo: bottomAnchor),
            authorAvatarView.leadingAnchor.pin(equalToSystemSpacingAfter: messageBubbleView.trailingAnchor, multiplier: 1)
        ]
    }

    override open func updateContent() {
        messageBubbleView.message = message.flatMap {
            .init(
                message: $0,
                parentMessageState: nil,
                isLastInGroup: true,
                didTapOnAttachment: nil,
                didTapOnAttachmentAction: nil
            )
        }
        messageBubbleView.isHidden = message == nil

        let placeholder = UIImage(named: "pattern1", in: .streamChatUI)
        if let imageURL = message?.author.imageURL {
            authorAvatarView.imageView.setImage(from: imageURL, placeholder: placeholder)
        } else {
            authorAvatarView.imageView.image = placeholder
        }
        authorAvatarView.isHidden = message == nil

        loadingView.isHidden = message != nil
        loadingView.isLoading = message == nil

        avatarOnTheLeftConstraints.forEach { $0.isActive = (message?.isSentByCurrentUser == false) }
        avatarOnTheRightConstraints.forEach { $0.isActive = (message?.isSentByCurrentUser == true) }
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
