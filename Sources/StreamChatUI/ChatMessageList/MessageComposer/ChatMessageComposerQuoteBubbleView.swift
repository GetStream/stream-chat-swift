//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageComposerQuoteBubbleView = _ChatMessageComposerQuoteBubbleView<NoExtraData>

internal class _ChatMessageComposerQuoteBubbleView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    // MARK: - Properties
    
    internal var avatarViewSize: CGSize = .init(width: 24, height: 24)
    internal var attachmentPreviewSize: CGSize = .init(width: 34, height: 34)
    
    internal var message: _ChatMessage<ExtraData>? {
        didSet {
            updateContentIfNeeded()
        }
    }
        
    // MARK: - Subviews
    
    internal private(set) lazy var container = UIStackView()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var contentView = UIView()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var authorAvatarView = uiConfig
        .messageComposer
        .quotedMessageAvatarView.init()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var attachmentPreview = UIImageView()
        .withoutAutoresizingMaskConstraints

    internal private(set) lazy var textView = UITextView()
        .withoutAutoresizingMaskConstraints
    
    // MARK: - Constraints
    
    internal var containerConstraints: [NSLayoutConstraint] = []
    internal var authorAvatarViewConstraints: [NSLayoutConstraint] = []
    internal var attachmentPreviewConstraints: [NSLayoutConstraint] = []
    internal var textViewConstraints: [NSLayoutConstraint] = []
    
    // MARK: - internal
    
    override internal func setUp() {
        super.setUp()
        
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.isScrollEnabled = false
        textView.adjustsFontForContentSizeCategory = true
        textView.isUserInteractionEnabled = false
    }
    
    override internal func defaultAppearance() {
        textView.textContainer.maximumNumberOfLines = 6
        textView.textContainer.lineBreakMode = .byTruncatingTail
        textView.textContainer.lineFragmentPadding = .zero
        
        textView.backgroundColor = .clear
        textView.font = uiConfig.fonts.subheadline
        textView.textContainerInset = .zero
        textView.textColor = uiConfig.colorPalette.text

        authorAvatarView.contentMode = .scaleAspectFit
        
        attachmentPreview.layer.cornerRadius = attachmentPreviewSize.width / 4
        attachmentPreview.layer.masksToBounds = true

        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = uiConfig.colorPalette.border.cgColor
        contentView.layer.masksToBounds = true
    }
    
    override internal func setUpLayout() {
        preservesSuperviewLayoutMargins = true
        
        addSubview(container)
        
        container.spacing = UIStackView.spacingUseSystem
        container.alignment = .bottom
        
        containerConstraints = [
            container.leadingAnchor.pin(equalTo: leadingAnchor, constant: directionalLayoutMargins.leading),
            container.trailingAnchor.pin(equalTo: trailingAnchor, constant: -directionalLayoutMargins.trailing),
            container.topAnchor.pin(equalTo: topAnchor, constant: directionalLayoutMargins.top),
            container.bottomAnchor.pin(equalTo: bottomAnchor, constant: -directionalLayoutMargins.bottom)
        ]
        
        authorAvatarViewConstraints = [
            authorAvatarView.widthAnchor.pin(equalToConstant: avatarViewSize.width),
            authorAvatarView.heightAnchor.pin(equalToConstant: avatarViewSize.height)
        ]
        
        container.addArrangedSubview(authorAvatarView)
        
        contentView.addSubview(attachmentPreview)
        
        attachmentPreviewConstraints = [
            attachmentPreview.widthAnchor.pin(equalToConstant: attachmentPreviewSize.width),
            attachmentPreview.heightAnchor.pin(equalToConstant: attachmentPreviewSize.height),
            attachmentPreview.leadingAnchor.pin(
                equalTo: contentView.leadingAnchor,
                constant: contentView.directionalLayoutMargins.leading
            ),
            attachmentPreview.topAnchor.pin(equalTo: contentView.topAnchor, constant: contentView.directionalLayoutMargins.top),
            attachmentPreview.bottomAnchor.pin(
                lessThanOrEqualTo: contentView.bottomAnchor,
                constant: -contentView.directionalLayoutMargins.bottom
            )
        ]
        
        contentView.addSubview(textView)
        
        textViewConstraints = [
            textView.topAnchor.pin(equalTo: contentView.topAnchor, constant: contentView.directionalLayoutMargins.top),
            textView.trailingAnchor.pin(
                equalTo: contentView.trailingAnchor,
                constant: -contentView.directionalLayoutMargins.trailing
            ),
            textView.bottomAnchor.pin(
                lessThanOrEqualTo: contentView.bottomAnchor,
                constant: -contentView.directionalLayoutMargins.bottom
            ),
            textView.leadingAnchor.pin(equalToSystemSpacingAfter: attachmentPreview.trailingAnchor, multiplier: 1)
        ]
                
        contentView.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner,
            .layerMaxXMaxYCorner
        ]
        
        container.addArrangedSubview(contentView)
        
        NSLayoutConstraint.activate(
            [containerConstraints, authorAvatarViewConstraints, attachmentPreviewConstraints, textViewConstraints].flatMap { $0 }
        )
    }
    
    override internal func updateContent() {
        guard let message = message else { return }
        
        let placeholder = uiConfig.images.userAvatarPlaceholder1
        if let imageURL = message.author.imageURL {
            authorAvatarView.imageView.loadImage(from: imageURL, placeholder: placeholder)
        } else {
            authorAvatarView.imageView.image = placeholder
        }
        
        textView.text = message.text
        updateAttachmentPreview(for: message)
    }
    
    // MARK: - Helpers
    
    internal func setAttachmentPreview(hidden: Bool) {
        if hidden {
            attachmentPreviewConstraints.prefix(3).forEach {
                $0.constant = 0
            }
        } else {
            attachmentPreviewConstraints[0].constant = attachmentPreviewSize.width
            attachmentPreviewConstraints[1].constant = attachmentPreviewSize.height
            attachmentPreviewConstraints[2].constant = contentView.directionalLayoutMargins.leading
        }
    }
    
    func updateAttachmentPreview(for message: _ChatMessage<ExtraData>) {
        // TODO: Take last attachment when they'll be ordered.
        guard let attachment = message.attachments.first else {
            attachmentPreview.image = nil
            setAttachmentPreview(hidden: true)
            return
        }
        
        switch attachment.type {
        case .file:
            // TODO: Question for designers.
            // I'm not sure if it will be possible to provide specific icon for all file formats
            // so probably we should stick to some generic like other apps do.
            print("set file icon")
            setAttachmentPreview(hidden: false)
            attachmentPreview.contentMode = .scaleAspectFit
        default:
            let attachment = attachment as? ChatMessageDefaultAttachment
            if let previewURL = attachment?.imagePreviewURL ?? attachment?.imageURL {
                attachmentPreview.loadImage(from: previewURL)
                setAttachmentPreview(hidden: false)
                attachmentPreview.contentMode = .scaleAspectFill
                // TODO: When we will have attachment examples we will set smth
                // different for different types.
                if message.text.isEmpty, attachment?.type == .image {
                    textView.text = "Photo"
                }
            } else {
                attachmentPreview.image = nil
                setAttachmentPreview(hidden: true)
            }
        }
    }
}
