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

        // Bubble view
        let bubbleView = createBubbleView()
        if options.contains(.continuousBubble) {
            bubbleView.roundedCorners = .all
            mainContainer.layoutMargins.bottom = 0

        } else if options.contains(.flipped) {
            bubbleView.roundedCorners = CACornerMask.all.subtracting(.layerMaxXMaxYCorner)

        } else {
            bubbleView.roundedCorners = CACornerMask.all.subtracting(.layerMinXMaxYCorner)
        }

        let bubbleContainer = ContainerView(axis: .vertical).withoutAutoresizingMaskConstraints
        bubbleView.embed(bubbleContainer)

        // Metadata
        if options.contains(.metadata) {
            let bubbleMetaContainer = ContainerView(
                axis: .vertical,
                alignment: options.contains(.flipped) ? .axisTrailing : .axisLeading,
                views: [bubbleView, createMetadataView()],
                spacing: 2
            )
            mainContainer.addArrangedSubview(bubbleMetaContainer)
        } else {
            mainContainer.addArrangedSubview(bubbleView)
        }

        // Text
        if options.contains(.text) {
            let textView = createTextView()
            bubbleContainer.addArrangedSubview(textView, respectsLayoutMargins: true)
        }

        // Link preview
        if options.contains(.linkPreview) {
            let linkPreviewView = createLinkPreviewView()
            bubbleContainer.addArrangedSubview(linkPreviewView, respectsLayoutMargins: true)
            constraintsToActivate += [
                // This is ugly. Ideally the link preview should be updated to fill all available space.
                linkPreviewView.widthAnchor.constraint(equalToConstant: window!.bounds.width * 0.75).almostRequired
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

        // Metadata
        metadataView?.content = content

        // Link preview
        linkPreviewView?.content = content?.attachments.first { $0.type.isLink } as? ChatMessageDefaultAttachment
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
}
