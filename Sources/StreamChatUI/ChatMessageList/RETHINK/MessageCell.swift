//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

class MessageCell<ExtraData: ExtraDataTypes>: _CollectionViewCell, UIConfigProvider {
    static var reuseId: String { "message_cell" }

    var content: _ChatMessage<ExtraData>? {
        didSet {
            updateContentIfNeeded()
        }
    }

    private var layoutOptions: ChatMessageLayoutOptions!
    
    var bubbleView: BubbleView<ExtraData>?
    var authorAvatarView: ChatAvatarView?
    var textView: UITextView?
    var metadataView: _ChatMessageMetadataView<ExtraData>?
    var linkPreviewView: _ChatMessageLinkPreviewView<ExtraData>?
    var quotedMessageView: _ChatMessageQuoteBubbleView<ExtraData>?
    var photoPreviewView: _ChatMessageImageGallery<ExtraData>?
    var filePreviewView: _ChatMessageFileAttachmentListView<ExtraData>?
    var giphyView: _ChatMessageGiphyView<ExtraData>?
    var actionsView: _ChatMessageInteractiveAttachmentView<ExtraData>?

    var threadReplyCountLabel: UILabel?
    var threadAvatarView: ChatAvatarView?
    var threadArrowView: _SimpleChatMessageThreadArrowView<ExtraData>?
    
    lazy var mainContainer: ContainerView = ContainerView(axis: .horizontal)
        .withoutAutoresizingMaskConstraints
    
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
        
        contentView.addSubview(mainContainer)
        constraintsToActivate += [
            mainContainer.topAnchor.pin(equalTo: contentView.topAnchor),
            mainContainer.bottomAnchor.pin(equalTo: contentView.bottomAnchor),
            mainContainer.widthAnchor.pin(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75)
        ]
        
        if options.contains(.flipped) {
            mainContainer.ordering = .trailingToLeading
            constraintsToActivate += [mainContainer.trailingAnchor.pin(equalTo: contentView.trailingAnchor)]
        } else {
            constraintsToActivate += [mainContainer.leadingAnchor.pin(equalTo: contentView.leadingAnchor)]
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
        let bubbleThreadMetaContainer = ContainerView(
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
            
            threadInfoContainer.addArrangedSubview(createThreadReplyCountLabel())
            
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

        // Bubble content
        let contentContainer = ContainerView(axis: .vertical).withoutAutoresizingMaskConstraints
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
        quotedMessageView?.message = content?.quotedMessage

        let attachments: _ChatMessageAttachmentListViewData<ExtraData>? = defaultAttachments.map {
            .init(
                attachments: $0,
                didTapOnAttachment: nil,
                didTapOnAttachmentAction: nil
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
            threadReplyCountLabel?.text = L10n.Message.Threads.count(replyCount)
        } else {
            threadReplyCountLabel?.text = L10n.Message.Threads.reply
        }
        let latestReplyAuthorAvatar = content?.latestReplies.first?.author.imageURL
        threadAvatarView?.imageView.loadImage(from: latestReplyAuthorAvatar)
    }
    
    override open func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        let preferredAttributes = super.preferredLayoutAttributesFitting(layoutAttributes)

        let targetSize = CGSize(
            width: layoutAttributes.frame.width,
            height: UIView.layoutFittingCompressedSize.height
        )

        preferredAttributes.frame.size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        return preferredAttributes
    }
}

// MARK: - Setups

private extension MessageCell {
    func createTextView() -> UITextView {
        if textView == nil {
            textView = OnlyLinkTappableTextView().withoutAutoresizingMaskConstraints
            textView?.isEditable = false
            textView?.dataDetectorTypes = .link
            textView?.isScrollEnabled = false
            textView?.backgroundColor = .clear
            textView?.adjustsFontForContentSizeCategory = true
            textView?.textContainerInset = .zero
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
    
    func createThreadReplyCountLabel() -> UILabel {
        if threadReplyCountLabel == nil {
            let label = UILabel().withoutAutoresizingMaskConstraints
            label.font = uiConfig.font.footnoteBold
            label.adjustsFontForContentSizeCategory = true
            label.text = L10n.Message.Threads.reply
            label.textColor = tintColor
            threadReplyCountLabel = label.withBidirectionalLanguagesSupport
        }
        return threadReplyCountLabel!
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
        }
        return linkPreviewView!
    }

    func createQuotedMessageView() -> _ChatMessageQuoteBubbleView<ExtraData> {
        if quotedMessageView == nil {
            quotedMessageView = uiConfig
                .messageList
                .messageContentSubviews
                .quotedMessageBubbleView
                .init()
                .withoutAutoresizingMaskConstraints
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
}
