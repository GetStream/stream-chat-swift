//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageComposerQuoteBubbleView = _ChatMessageComposerQuoteBubbleView<NoExtraData>

open class _ChatMessageComposerQuoteBubbleView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    // MARK: - Properties
    
    public var avatarViewWidth: CGFloat = 24
    public var attachmentPreviewWidth: CGFloat = 34
    
    public var message: _ChatMessage<ExtraData>? {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    lazy var textViewHeightConstraint = textView.heightAnchor.pin(greaterThanOrEqualToConstant: .zero)
    
    // MARK: - Subviews
    
    public private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var authorAvatarView = uiConfig
        .messageComposer
        .quotedMessageAvatarView.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var attachmentPreview = UIImageView()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var textView = UITextView()
        .withoutAutoresizingMaskConstraints
    
    // MARK: - Public
    
    override open func setUp() {
        super.setUp()
        
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.isScrollEnabled = false
        textView.adjustsFontForContentSizeCategory = true
        textView.isUserInteractionEnabled = false
    }
    
    override public func defaultAppearance() {
        textView.textContainer.maximumNumberOfLines = 6
        textView.textContainer.lineBreakMode = .byTruncatingTail
        textView.textContainer.lineFragmentPadding = .zero
        
        textView.backgroundColor = .clear
        textView.font = uiConfig.font.subheadline
        textView.textContainerInset = .zero
        textView.textColor = uiConfig.colorPalette.text

        authorAvatarView.contentMode = .scaleAspectFit
        
        attachmentPreview.layer.cornerRadius = attachmentPreviewWidth / 4
        attachmentPreview.layer.masksToBounds = true
        
        container.centerStackView.layer.cornerRadius = 16
        container.centerStackView.layer.borderWidth = 1
        container.centerStackView.layer.borderColor = uiConfig.colorPalette.messageComposerBorder.cgColor
        container.centerStackView.layer.masksToBounds = true
    }
    
    override open func setUpLayout() {
        embed(container)
        
        preservesSuperviewLayoutMargins = true
        
        container.preservesSuperviewLayoutMargins = true
        container.isLayoutMarginsRelativeArrangement = true
        
        container.leftStackView.isHidden = false
        container.leftStackView.addArrangedSubview(authorAvatarView)
        authorAvatarView.widthAnchor.pin(equalToConstant: avatarViewWidth).isActive = true
        authorAvatarView.heightAnchor.pin(equalTo: authorAvatarView.widthAnchor, multiplier: 1).isActive = true
        
        container.centerContainerStackView.spacing = UIStackView.spacingUseSystem
        container.centerContainerStackView.alignment = .bottom
        
        container.centerStackView.isLayoutMarginsRelativeArrangement = true
        container.centerStackView.layoutMargins = layoutMargins
        
        container.centerStackView.isHidden = false
        container.centerStackView.spacing = UIStackView.spacingUseSystem
        container.centerStackView.alignment = .top
        container.centerStackView.addArrangedSubview(attachmentPreview)

        attachmentPreview.widthAnchor.pin(equalToConstant: attachmentPreviewWidth).isActive = true
        attachmentPreview.heightAnchor.pin(equalTo: attachmentPreview.widthAnchor, multiplier: 1).isActive = true

        container.centerStackView.addArrangedSubview(textView)
        
        textView.setContentHuggingPriority(.required, for: .vertical)
        
        textViewHeightConstraint.isActive = true
        
        container.centerStackView.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner,
            .layerMaxXMaxYCorner
        ]
    }
    
    override open func updateContent() {
        guard let message = message else { return }
        
        let placeholder = UIImage(named: "pattern1", in: .streamChatUI)
        if let imageURL = message.author.imageURL {
            authorAvatarView.imageView.setImage(from: imageURL, placeholder: placeholder)
        } else {
            authorAvatarView.imageView.image = placeholder
        }
        
        textView.text = message.text
        
        updateAttachmentPreview(for: message)
        
        textViewHeightConstraint.constant = textView.calculatedTextHeight()
    }
    
    // MARK: - Helpers
    
    func updateAttachmentPreview(for message: _ChatMessage<ExtraData>) {
        // TODO: Take last attachment when they'll be ordered.
        guard let attachment = message.attachments.first else {
            attachmentPreview.image = nil
            attachmentPreview.isHidden = true
            return
        }
        
        switch attachment.type {
        case .file:
            // TODO: Question for designers.
            // I'm not sure if it will be possible to provide specific icon for all file formats
            // so probably we should stick to some generic like other apps do.
            print("set file icon")
            attachmentPreview.isHidden = false
            attachmentPreview.contentMode = .scaleAspectFit
        default:
            if let previewURL = attachment.imagePreviewURL ?? attachment.imageURL {
                attachmentPreview.setImage(from: previewURL)
                attachmentPreview.isHidden = false
                attachmentPreview.contentMode = .scaleAspectFill
                // TODO: When we will have attachment examples we will set smth
                // different for different types.
                if message.text.isEmpty, attachment.type == .image {
                    textView.text = "Photo"
                }
            } else {
                attachmentPreview.image = nil
                attachmentPreview.isHidden = true
            }
        }
    }
}
