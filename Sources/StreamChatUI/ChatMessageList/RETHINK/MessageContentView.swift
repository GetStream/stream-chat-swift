//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension MessageContentView {
    struct Delegate {
        var didTapOnErrorIndicator: () -> Void
        var didTapOnThread: () -> Void
        var didTapOnAttachment: (ChatMessageAttachment) -> Void
        var didTapOnAttachmentAction: (ChatMessageAttachment, AttachmentAction) -> Void
        var didTapOnQuotedMessage: (_ChatMessage<ExtraData>) -> Void
    }
}

class MessageContentView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    var content: _ChatMessage<ExtraData>? {
        didSet {
            updateContentIfNeeded()
        }
    }

    var delegate: Delegate? {
        didSet {
            // We need this since the action closures for `photo/file` previews
            // are set up in `updateContent`. After dequeuing the cell we set content AND the delegate which results
            // in 2 `updateContent` executions and should be fixed/reimplemented.
            updateContentIfNeeded()
        }
    }

    private var layoutOptions: ChatMessageLayoutOptions!
    
    var bubbleView: BubbleView<ExtraData>?
    var authorAvatarView: ChatAvatarView?
    var textView: UITextView?
    var metadataView: _ChatMessageMetadataView<ExtraData>?
    var linkPreviewView: _ChatMessageLinkPreviewView<ExtraData>?
    var quotedMessageView: _ChatMessageQuoteView<ExtraData>?
    var photoPreviewView: _ChatMessageImageGallery<ExtraData>?
    var filePreviewView: _ChatMessageFileAttachmentListView<ExtraData>?
    var giphyView: _ChatMessageGiphyView<ExtraData>?
    var actionsView: _ChatMessageInteractiveAttachmentView<ExtraData>?
    var errorIndicatorView: _ChatMessageErrorIndicator<ExtraData>?

    var reactionsView: _ReactionsCompactView<ExtraData>?
    var reactionsBubbleView: ReactionsBubbleView<ExtraData>?

    var threadReplyCountButton: UIButton?
    var threadAvatarView: ChatAvatarView?
    var threadArrowView: _SimpleChatMessageThreadArrowView<ExtraData>?
    
    lazy var mainContainer = ContainerStackView(axis: .horizontal)
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
        
        layoutOptions = options
        
        var constraintsToActivate: [NSLayoutConstraint] = []
        
        // Main container
        mainContainer.alignment = .axisTrailing
        mainContainer.isLayoutMarginsRelativeArrangement = true
        mainContainer.layoutMargins.top = 0
        
        addSubview(mainContainer)
        constraintsToActivate += [
            mainContainer.topAnchor.pin(equalTo: topAnchor).with(priority: .streamAlmostRequire),
            mainContainer.bottomAnchor.pin(equalTo: bottomAnchor),
            mainContainer.widthAnchor.pin(lessThanOrEqualTo: widthAnchor, multiplier: 0.75)
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
        let bubbleThreadMetaContainer = ContainerStackView(
            axis: .vertical,
            alignment: options.contains(.flipped) ? .axisTrailing : .axisLeading,
            spacing: 4
        )
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
            let threadInfoContainer = ContainerStackView()
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
            threadReplyCountButton.addTarget(self, action: #selector(didTapOnThread), for: .touchUpInside)
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
        let contentContainer = ContainerStackView(axis: .vertical).withoutAutoresizingMaskConstraints
        bubbleView.embed(contentContainer)

        // Quoted message
        if options.contains(.quotedMessage) {
            let quotedMessageView = createQuotedMessageView()
            contentContainer.addArrangedSubview(quotedMessageView, respectsLayoutMargins: true)
        }
        
        // Photo preview
        if options.contains(.photoPreview) {
            let photoPreviewView = createPhotoPreviewView()
            contentContainer.addArrangedSubview(photoPreviewView, respectsLayoutMargins: false)
            constraintsToActivate += [
                // This is ugly. Ideally the photo preview should be updated to fill all available space.
                photoPreviewView.widthAnchor.constraint(equalToConstant: window!.bounds.width * 0.75).almostRequired
            ]
        }

        // Giphy
        if options.contains(.giphy) {
            let giphyView = createGiphyView()
            contentContainer.addArrangedSubview(giphyView, respectsLayoutMargins: false)
            constraintsToActivate += [
                // This is ugly. Ideally the photo preview should be updated to fill all available space.
                giphyView.widthAnchor.constraint(equalToConstant: window!.bounds.width * 0.75).almostRequired
            ]
        }

        // Text
        if options.contains(.text) {
            let textView = createTextView()
            contentContainer.addArrangedSubview(textView, respectsLayoutMargins: true)
        }

        // File previews
        if options.contains(.filePreview) {
            let filePreviewView = createFilePreviewView()
            contentContainer.addArrangedSubview(filePreviewView, respectsLayoutMargins: false)
        }

        // Link preview
        if options.contains(.linkPreview) {
            let linkPreviewView = createLinkPreviewView()
            contentContainer.addArrangedSubview(linkPreviewView, respectsLayoutMargins: true)
            constraintsToActivate += [
                // This is ugly. Ideally the link preview should be updated to fill all available space.
                linkPreviewView.widthAnchor.constraint(equalToConstant: window!.bounds.width * 0.75).almostRequired
            ]
        }

        // Actions
        if options.contains(.actions) {
            let actionsView = createActionsView()
            contentContainer.addArrangedSubview(actionsView, respectsLayoutMargins: false)
            constraintsToActivate += [
                // This is ugly. Ideally the action view should be updated to fill all available space.
                actionsView.widthAnchor.constraint(equalToConstant: window!.bounds.width * 0.75).almostRequired
            ]
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
            
        } else if layoutOptions?.contains(.linkPreview) == true {
            bubbleView?.backgroundColor = uiConfig.colorPalette.highlightedAccentBackground1
            
        } else {
            bubbleView?.backgroundColor = content?.isSentByCurrentUser == true ?
                uiConfig.colorPalette.background2 :
                uiConfig.colorPalette.popoverBackground
        }

        let defaultAttachments = content?.attachments.compactMap { $0 as? ChatMessageDefaultAttachment }

        // Metadata
        metadataView?.content = content

        // Link preview
        linkPreviewView?.content = defaultAttachments?.first { $0.type.isLink }

        // Quoted message view
        quotedMessageView?.content = content?.quotedMessage.map {
            .init(message: $0, avatarAlignment: $0.isSentByCurrentUser ? .right : .left)
        }

        let attachments: _ChatMessageAttachmentListViewData<ExtraData>? = defaultAttachments.map {
            .init(
                attachments: $0,
                didTapOnAttachment: { [weak self] in
                    self?.delegate?.didTapOnAttachment($0)
                },
                didTapOnAttachmentAction: { [weak self] in
                    self?.delegate?.didTapOnAttachmentAction($0, $1)
                }
            )
        }

        // Photo preview
        photoPreviewView?.content = attachments

        // File preview
        filePreviewView?.content = attachments

        // Giphy view
        giphyView?.content = defaultAttachments?.first { $0.type == .giphy }

        // Actions view
        actionsView?.content = attachments?.items.first { !$0.attachment.actions.isEmpty }

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

    // MARK: - Actions

    @objc func didTapOnErrorIndicator() {
        delegate?.didTapOnThread()
    }

    @objc func didTapOnThread() {
        delegate?.didTapOnThread()
    }

    @objc func didTapOnLinkPreview() {
        guard let attachment = linkPreviewView?.content else {
            assertionFailure()
            return
        }

        delegate?.didTapOnAttachment(attachment)
    }

    @objc func didTapOnQuotedMessage() {
        guard let quotedMessage = quotedMessageView?.content?.message else {
            assertionFailure()
            return
        }

        delegate?.didTapOnQuotedMessage(quotedMessage)
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

    func createLinkPreviewView() -> _ChatMessageLinkPreviewView<ExtraData> {
        if linkPreviewView == nil {
            linkPreviewView = uiConfig
                .messageList
                .messageContentSubviews
                .linkPreviewView
                .init()
                .withoutAutoresizingMaskConstraints

            linkPreviewView!.addTarget(self, action: #selector(didTapOnLinkPreview), for: .touchUpInside)
        }
        return linkPreviewView!
    }

    func createQuotedMessageView() -> _ChatMessageQuoteView<ExtraData> {
        if quotedMessageView == nil {
            quotedMessageView = uiConfig
                .messageQuoteView
                .init()
                .withoutAutoresizingMaskConstraints

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnQuotedMessage))
            quotedMessageView!.addGestureRecognizer(tapRecognizer)
        }
        return quotedMessageView!
    }

    func createPhotoPreviewView() -> _ChatMessageImageGallery<ExtraData> {
        if photoPreviewView == nil {
            photoPreviewView = uiConfig
                .messageList
                .messageContentSubviews
                .attachmentSubviews
                .imageGallery
                .init()
                .withoutAutoresizingMaskConstraints
        }
        return photoPreviewView!
    }

    func createFilePreviewView() -> _ChatMessageFileAttachmentListView<ExtraData> {
        if filePreviewView == nil {
            filePreviewView = uiConfig
                .messageList
                .messageContentSubviews
                .attachmentSubviews
                .fileAttachmentListView
                .init()
                .withoutAutoresizingMaskConstraints
        }
        return filePreviewView!
    }

    func createGiphyView() -> _ChatMessageGiphyView<ExtraData> {
        if giphyView == nil {
            giphyView = uiConfig
                .messageList
                .messageContentSubviews
                .attachmentSubviews
                .giphyAttachmentView
                .init()
                .withoutAutoresizingMaskConstraints
        }
        return giphyView!
    }

    func createActionsView() -> _ChatMessageInteractiveAttachmentView<ExtraData> {
        if actionsView == nil {
            actionsView = uiConfig
                .messageList
                .messageContentSubviews
                .attachmentSubviews
                .interactiveAttachmentView
                .init()
                .withoutAutoresizingMaskConstraints
        }
        return actionsView!
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

            errorIndicatorView!.addTarget(self, action: #selector(didTapOnErrorIndicator), for: .touchUpInside)
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
