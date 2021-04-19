//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public protocol MessageContentViewDelegate: AnyObject {
    func didTapOnErrorIndicator(at indexPath: IndexPath)
    func didTapOnThread(at indexPath: IndexPath)
    func didTapOnQuotedMessage(at indexPath: IndexPath)
}

class MessageContentView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    private var layoutOptions: ChatMessageLayoutOptions!

    // MARK: Content && Actions

    var indexPath: IndexPath?
    weak var delegate: MessageContentViewDelegate?

    var content: _ChatMessage<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: Content views

    var bubbleView: BubbleView<ExtraData>?
    var authorAvatarView: ChatAvatarView?
    var textView: UITextView?
    var metadataView: _ChatMessageMetadataView<ExtraData>?
    var errorIndicatorView: _ChatMessageErrorIndicator<ExtraData>?
    var quotedMessageView: _ChatMessageQuoteBubbleView<ExtraData>?
    var reactionsView: _ReactionsCompactView<ExtraData>?
    var reactionsBubbleView: ReactionsBubbleView<ExtraData>?
    var threadReplyCountButton: UIButton?
    var threadAvatarView: ChatAvatarView?
    var threadArrowView: _SimpleChatMessageThreadArrowView<ExtraData>?

    // MARK: Containers

    var maxContentWidthMultiplier: CGFloat { 0.75 }
    lazy var mainContainer = ContainerView(axis: .horizontal)
        .withoutAutoresizingMaskConstraints
    lazy var bubbleThreadMetaContainer = ContainerView(axis: .vertical, spacing: 4)
        .withoutAutoresizingMaskConstraints
    lazy var bubbleContentContainer = ContainerView(axis: .vertical)
        .withoutAutoresizingMaskConstraints

    override func layoutSubviews() {
        super.layoutSubviews()

        maskContainerByReactionsBubble()
    }

    func maskContainerByReactionsBubble() {
        guard let reactionsBubble = reactionsBubbleView else {
            mainContainer.mask = nil
            return
        }

        let bubbleOriginInMainContainer = reactionsBubble.superview!
            .convert(reactionsBubble.frame.origin, to: mainContainer)

        let moveToMainContainer = CGAffineTransform(
            translationX: bubbleOriginInMainContainer.x,
            y: bubbleOriginInMainContainer.y
        )

        let conainerMaskingPath = reactionsBubble.maskingPath
        conainerMaskingPath.apply(moveToMainContainer)

        let maskImage = UIGraphicsImageRenderer(size: mainContainer.bounds.size)
            .image {
                let layer = CAShapeLayer()
                layer.path = conainerMaskingPath.cgPath
                layer.render(in: $0.cgContext)
            }
            .asAlphaMask()

        mainContainer.mask = UIImageView(image: maskImage)
    }
    
    func setUpLayoutIfNeeded(options: ChatMessageLayoutOptions) {
        guard layoutOptions == nil else {
            assert(layoutOptions == options, "Attempt to apply different layout")
            return
        }
        layout(options: options)
        layoutOptions = options
    }

    func layout(options: ChatMessageLayoutOptions) {
        var constraintsToActivate: [NSLayoutConstraint] = []

        // Main container
        mainContainer.alignment = .axisTrailing
        mainContainer.isLayoutMarginsRelativeArrangement = true
        mainContainer.layoutMargins.top = 0

        addSubview(mainContainer)
        constraintsToActivate += [
            mainContainer.topAnchor.pin(equalTo: topAnchor).with(priority: .streamAlmostRequire),
            mainContainer.bottomAnchor.pin(equalTo: bottomAnchor),
            options.contains(.maxWidth) ?
                mainContainer.widthAnchor.pin(
                    equalTo: widthAnchor,
                    multiplier: maxContentWidthMultiplier
                ) :
                mainContainer.widthAnchor.pin(
                    lessThanOrEqualTo: widthAnchor,
                    multiplier: maxContentWidthMultiplier
                )
        ]
        
        if options.contains(.flipped) {
            mainContainer.ordering = .trailingToLeading
            constraintsToActivate += [
                mainContainer.trailingAnchor
                    .pin(equalTo: trailingAnchor)
                    .almostRequired
            ]
        } else {
            constraintsToActivate += [
                mainContainer.leadingAnchor
                    .pin(equalTo: leadingAnchor)
                    .almostRequired
            ]
        }

        // Avatar view
        if options.contains(.avatar) {
            let avatarView = createAvatarView()
            constraintsToActivate += [
                avatarView.widthAnchor.pin(equalToConstant: 32),
                avatarView.heightAnchor.pin(equalToConstant: 32)
            ]

            mainContainer.addArrangedSubview(avatarView)
        }
        
        if options.contains(.avatarSizePadding) {
            let spacer = UIView().withoutAutoresizingMaskConstraints
            spacer.isHidden = true
            constraintsToActivate += [spacer.widthAnchor.pin(equalToConstant: 32)]
            mainContainer.addArrangedSubview(spacer)
        }

        // Bubble - Thread - Metadata
        bubbleThreadMetaContainer.alignment = options.contains(.flipped) ? .axisTrailing : .axisLeading
        mainContainer.addArrangedSubview(bubbleThreadMetaContainer)

        // Bubble view
        let bubbleView = createBubbleView()
        bubbleThreadMetaContainer.addArrangedSubview(bubbleView)

        if options.contains(.continuousBubble) {
            bubbleView.roundedCorners = .all
            mainContainer.layoutMargins.bottom = 0
        } else if options.contains(.flipped) {
            bubbleView.roundedCorners = CACornerMask.all.subtracting(.layerMaxXMaxYCorner)
        } else {
            bubbleView.roundedCorners = CACornerMask.all.subtracting(.layerMinXMaxYCorner)
        }

        // Thread info
        if options.contains(.threadInfo) {
            let threadInfoContainer = ContainerView()
            bubbleThreadMetaContainer.addArrangedSubview(threadInfoContainer)
            
            let arrowView = createThreadArrowView()
            threadInfoContainer.addArrangedSubview(arrowView)
            threadInfoContainer.setCustomSpacing(0, after: arrowView)
            
            let threadAvatarView = createThreadAvatarView()
            threadInfoContainer.addArrangedSubview(threadAvatarView)
            constraintsToActivate += [
                threadAvatarView.widthAnchor.constraint(equalTo: threadAvatarView.heightAnchor),
                threadAvatarView.widthAnchor.constraint(equalToConstant: 16)
            ]
            
            let threadReplyCountButton = createThreadReplyCountButton()
            threadInfoContainer.addArrangedSubview(threadReplyCountButton)
            
            if options.contains(.flipped) {
                arrowView.direction = .toLeading
                threadInfoContainer.ordering = .trailingToLeading
            }
        }

        // Metadata
        if options.contains(.metadata) {
            let metadataView = createMetadataView()
            bubbleThreadMetaContainer.addArrangedSubview(metadataView)
        }

        // Error
        if options.contains(.error) {
            let errorIndicatorView = createErrorIndicatorView()
            errorIndicatorView.setContentCompressionResistancePriority(.streamRequire, for: .horizontal)
            errorIndicatorView.setContentCompressionResistancePriority(.streamRequire, for: .vertical)
            addSubview(errorIndicatorView)

            constraintsToActivate += [
                errorIndicatorView.bottomAnchor.pin(equalTo: bubbleView.bottomAnchor),
                errorIndicatorView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
                bubbleThreadMetaContainer.trailingAnchor.pin(equalTo: errorIndicatorView.centerXAnchor)
            ]
        }

        // Bubble content
        bubbleView.embed(bubbleContentContainer)

        // Quoted message
        if options.contains(.quotedMessage) {
            let quotedMessageView = createQuotedMessageView()
            bubbleContentContainer.addArrangedSubview(quotedMessageView, respectsLayoutMargins: true)
        }

        // Text
        if options.contains(.text) {
            let textView = createTextView()
            bubbleContentContainer.addArrangedSubview(textView, respectsLayoutMargins: true)
        }

        // Reactions
        if options.contains(.reactions) {
            let reactionsBubbleView = createReactionsBubbleView()
            addSubview(reactionsBubbleView)

            let reactionsView = createReactionsView()
            reactionsBubbleView.addSubview(reactionsView)
            reactionsView.pin(to: reactionsBubbleView.layoutMarginsGuide)

            constraintsToActivate += [
                reactionsBubbleView.topAnchor.pin(equalTo: topAnchor),
                bubbleView.topAnchor.pin(equalTo: reactionsBubbleView.centerYAnchor),
                reactionsBubbleView.centerXAnchor.pin(
                    equalTo: options.contains(.flipped) ?
                        mainContainer.leadingAnchor :
                        mainContainer.trailingAnchor
                )
            ]
        }
        
        NSLayoutConstraint.activate(constraintsToActivate)
    }

    override func updateContent() {
        // Text
        textView?.text = content?.text
        
        // Avatar
        let placeholder = uiConfig.images.userAvatarPlaceholder1
        if let imageURL = content?.author.imageURL {
            authorAvatarView?.imageView.loadImage(from: imageURL, placeholder: placeholder)
        } else {
            authorAvatarView?.imageView.image = placeholder
        }
        
        // Bubble view
        if content?.type == .ephemeral {
            bubbleView?.backgroundColor = uiConfig.colorPalette.popoverBackground
        } else {
            bubbleView?.backgroundColor = content?.isSentByCurrentUser == true ?
                uiConfig.colorPalette.background2 :
                uiConfig.colorPalette.popoverBackground
        }

        // Metadata
        metadataView?.authorLabel.isVisible = layoutOptions?.contains(.authorName) ?? false
        metadataView?.content = content

        // Quoted message view
        quotedMessageView?.message = content?.quotedMessage

        // Thread info
        if let replyCount = content?.replyCount {
            threadReplyCountButton?.setTitle(L10n.Message.Threads.count(replyCount), for: .normal)
        } else {
            threadReplyCountButton?.setTitle(L10n.Message.Threads.reply, for: .normal)
        }
        let latestReplyAuthorAvatar = content?.latestReplies.first?.author.imageURL
        threadAvatarView?.imageView.loadImage(from: latestReplyAuthorAvatar)

        // Reactions view
        reactionsBubbleView?.tailDirection = content
            .map { $0.isSentByCurrentUser ? .toTrailing : .toLeading }
        reactionsView?.content = content
    }

    func prepareForReuse() {
        content = nil
        delegate = nil
        indexPath = nil
    }

    // MARK: - Actions

    @objc func handleTapOnErrorIndicator() {
        guard let indexPath = indexPath else { return }
        delegate?.didTapOnErrorIndicator(at: indexPath)
    }

    @objc func handleTapOnThread() {
        guard let indexPath = indexPath else { return }
        delegate?.didTapOnThread(at: indexPath)
    }

    @objc func handleTapOnQuotedMessage() {
        guard let quotedMessage = quotedMessageView?.message else {
            assertionFailure()
            return
        }

        guard let indexPath = indexPath else { return }
        delegate?.didTapOnQuotedMessage(at: indexPath)
    }
}

// MARK: - Setups

private extension MessageContentView {
    func createTextView() -> UITextView {
        if textView == nil {
            textView = OnlyLinkTappableTextView().withoutAutoresizingMaskConstraints
            textView?.isEditable = false
            textView?.dataDetectorTypes = .link
            textView?.isScrollEnabled = false
            textView?.backgroundColor = .clear
            textView?.adjustsFontForContentSizeCategory = true
            textView?.textContainerInset = .init(top: 0, left: 8, bottom: 0, right: 8)
            textView?.textContainer.lineFragmentPadding = 0
            textView?.translatesAutoresizingMaskIntoConstraints = false
            textView?.font = uiConfig.font.body
        }
        return textView!
    }

    func createAvatarView() -> ChatAvatarView {
        if authorAvatarView == nil {
            authorAvatarView = uiConfig
                .messageList
                .messageContentSubviews
                .authorAvatarView
                .init()
                .withoutAutoresizingMaskConstraints
        }
        return authorAvatarView!
    }

    func createThreadAvatarView() -> ChatAvatarView {
        if threadAvatarView == nil {
            threadAvatarView = uiConfig
                .messageList
                .messageContentSubviews
                .authorAvatarView
                .init()
                .withoutAutoresizingMaskConstraints
        }
        return threadAvatarView!
    }

    func createThreadArrowView() -> _SimpleChatMessageThreadArrowView<ExtraData> {
        if threadArrowView == nil {
            threadArrowView = .init()
        }
        return threadArrowView!
    }
    
    func createThreadReplyCountButton() -> UIButton {
        if threadReplyCountButton == nil {
            let button = UIButton(type: .system)
            button.setTitle(L10n.Message.Threads.reply, for: [])
            button.setTitleColor(tintColor, for: .normal)
            button.titleLabel?.font = uiConfig.font.footnoteBold
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.titleLabel?.textAlignment = .natural
            button.addTarget(self, action: #selector(handleTapOnThread), for: .touchUpInside)
            threadReplyCountButton = button
        }
        return threadReplyCountButton!
    }

    func createBubbleView() -> BubbleView<ExtraData> {
        if bubbleView == nil {
            bubbleView = BubbleView<ExtraData>().withoutAutoresizingMaskConstraints
        }
        return bubbleView!
    }

    func createMetadataView() -> _ChatMessageMetadataView<ExtraData> {
        if metadataView == nil {
            metadataView = uiConfig
                .messageList
                .messageContentSubviews
                .metadataView
                .init()
                .withoutAutoresizingMaskConstraints
        }
        return metadataView!
    }

    func createQuotedMessageView() -> _ChatMessageQuoteBubbleView<ExtraData> {
        if quotedMessageView == nil {
            quotedMessageView = uiConfig
                .messageList
                .messageContentSubviews
                .quotedMessageBubbleView
                .init()
                .withoutAutoresizingMaskConstraints

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapOnQuotedMessage))
            quotedMessageView!.addGestureRecognizer(tapRecognizer)
        }
        return quotedMessageView!
    }

    func createReactionsView() -> _ReactionsCompactView<ExtraData> {
        if reactionsView == nil {
            reactionsView = _ReactionsCompactView()
                .withoutAutoresizingMaskConstraints
        }
        return reactionsView!
    }

    func createErrorIndicatorView() -> _ChatMessageErrorIndicator<ExtraData> {
        if errorIndicatorView == nil {
            errorIndicatorView = uiConfig
                .messageList
                .messageContentSubviews
                .errorIndicator
                .init()
                .withoutAutoresizingMaskConstraints

            errorIndicatorView!.addTarget(self, action: #selector(handleTapOnErrorIndicator), for: .touchUpInside)
        }
        return errorIndicatorView!
    }

    func createReactionsBubbleView() -> ReactionsBubbleView<ExtraData> {
        if reactionsBubbleView == nil {
            reactionsBubbleView = ReactionsBubbleView()
                .withoutAutoresizingMaskConstraints
        }
        return reactionsBubbleView!
    }
}
