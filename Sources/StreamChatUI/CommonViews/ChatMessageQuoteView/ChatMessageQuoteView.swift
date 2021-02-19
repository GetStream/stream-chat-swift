//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The avatar position in relation with the text message.
struct ChatMessageQuoteAvatarAlignment: Equatable {
    /// The avatar will be aligned to the left, and the message content on the right.
    static let left = ChatMessageQuoteAvatarAlignment(rawValue: 0)
    /// The avatar will be aligned to the right, and the message content on the left.
    static let right = ChatMessageQuoteAvatarAlignment(rawValue: 1)

    private let rawValue: Int
}

/// A view that displays a quoted message.
internal typealias ChatMessageQuoteView = _ChatMessageQuoteView<NoExtraData>

/// A view that displays a quoted message.
internal class _ChatMessageQuoteView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    /// The `ChatMessageQuoteView` content.
    internal struct Content {
        /// The quoted message.
        let message: _ChatMessage<ExtraData>?
        /// The avatar position in relation with the text message.
        let avatarAlignment: ChatMessageQuoteAvatarAlignment
    }

    /// The content of this view, composed by the quoted message and the desired avatar alignment.
    internal var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The container view that holds the `authorAvatarView` and the `contentContainerView`.
    internal private(set) lazy var containerView: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// The avatar view of the author's quoted message.
    internal private(set) lazy var authorAvatarView: ChatAvatarView = uiConfig
        .avatarView.init()
        .withoutAutoresizingMaskConstraints

    /// The container view that holds the `textView` and the `attachmentPreview`.
    internal private(set) lazy var contentContainerView: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// The `UITextView` that contains quoted message content.
    internal private(set) lazy var textView: UITextView = UITextView()
        .withoutAutoresizingMaskConstraints

    /// The attachment preview view if the quoted message has an attachment.
    internal private(set) lazy var attachmentPreviewView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

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

        contentContainerView.layer.cornerRadius = 16
        contentContainerView.layer.borderWidth = 1
        contentContainerView.layer.borderColor = uiConfig.colorPalette.border.cgColor
        contentContainerView.layer.masksToBounds = true
    }

    override internal func setUpLayout() {
        preservesSuperviewLayoutMargins = true

        containerView.isLayoutMarginsRelativeArrangement = true
        containerView.spacing = .auto
        containerView.alignment = .axisTrailing

        contentContainerView.isLayoutMarginsRelativeArrangement = true
        contentContainerView.alignment = .axisLeading

        embed(containerView)
        containerView.addArrangedSubview(authorAvatarView)
        containerView.addArrangedSubview(contentContainerView)
        
        contentContainerView.addArrangedSubview(attachmentPreviewView)
        contentContainerView.addArrangedSubview(textView)

        let authorAvatarSize = CGSize(width: 24, height: 24)

        NSLayoutConstraint.activate([
            authorAvatarView.widthAnchor.pin(equalToConstant: authorAvatarSize.width),
            authorAvatarView.heightAnchor.pin(equalToConstant: authorAvatarSize.height)
        ])

        let attachmentPreviewSize = CGSize(width: 34, height: 34)

        NSLayoutConstraint.activate([
            attachmentPreviewView.widthAnchor.pin(equalToConstant: attachmentPreviewSize.width),
            attachmentPreviewView.heightAnchor.pin(equalToConstant: attachmentPreviewSize.height)
        ])

        attachmentPreviewView.layer.cornerRadius = attachmentPreviewSize.width / 4
        attachmentPreviewView.layer.masksToBounds = true
    }

    override internal func updateContent() {
        guard let message = content?.message else { return }
        guard let avatarAlignment = content?.avatarAlignment else { return }

        setAvatar(imageUrl: message.author.imageURL)
        setText(message.text)
        setAttachmentPreview(for: message)

        switch avatarAlignment {
        case .left:
            setAvatarPosition(.left)
        case .right:
            setAvatarPosition(.right)
        default:
            break
        }
    }
}

private extension _ChatMessageQuoteView {
    /// Sets the avatar image from a url or sets the placeholder image if the url is `nil`.
    /// - Parameter imageUrl: The url of the image.
    func setAvatar(imageUrl: URL?) {
        let placeholder = uiConfig.images.userAvatarPlaceholder1
        authorAvatarView.imageView.loadImage(from: imageUrl, placeholder: placeholder)
    }

    /// Sets the text of the `textView`.
    /// - Parameter text: The content of the text view.
    func setText(_ text: String) {
        textView.text = text
    }

    /// The avatar position in relation of the text bubble.
    enum AvatarPosition {
        case left
        case right
    }

    /// Sets the avatar position in relation of the text bubble.
    /// - Parameter position: The avatar position.
    func setAvatarPosition(_ position: AvatarPosition) {
        authorAvatarView.removeFromSuperview()
        switch position {
        case .left:
            containerView.insertArrangedSubview(authorAvatarView, at: 0)
            contentContainerView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMaxXMaxYCorner
            ]
        case .right:
            containerView.addArrangedSubview(authorAvatarView)
            contentContainerView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMinXMaxYCorner
            ]
        }
    }

    /// Sets the attachment view or hides it if no attachment found in the message.
    /// - Parameter message: The message owner of the attachment.
    func setAttachmentPreview(for message: _ChatMessage<ExtraData>) {
        // TODO: Take last attachment when they'll be ordered.
        guard let attachment = message.attachments.first else {
            attachmentPreviewView.image = nil
            hideAttachmentPreview()
            return
        }

        switch attachment.type {
        case .file:
            // TODO: Question for designers.
            // I'm not sure if it will be possible to provide specific icon for all file formats
            // so probably we should stick to some generic like other apps do.
            print("set file icon")
            showAttachmentPreview()
            attachmentPreviewView.contentMode = .scaleAspectFit
        default:
            let attachment = attachment as? ChatMessageDefaultAttachment
            if let previewURL = attachment?.imagePreviewURL ?? attachment?.imageURL {
                attachmentPreviewView.loadImage(from: previewURL)
                showAttachmentPreview()
                attachmentPreviewView.contentMode = .scaleAspectFill
                // TODO: When we will have attachment examples we will set smth
                // different for different types.
                if message.text.isEmpty, attachment?.type == .image {
                    textView.text = "Photo"
                }
            } else {
                attachmentPreviewView.image = nil
                hideAttachmentPreview()
            }
        }
    }

    /// Show the attachment preview view.
    func showAttachmentPreview() {
        contentContainerView.showSubview(attachmentPreviewView, animated: false)
    }

    /// Hide the attachment preview view.
    func hideAttachmentPreview() {
        contentContainerView.hideSubview(attachmentPreviewView, animated: false)
    }
}
