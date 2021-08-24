//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The quoted author's avatar position in relation with the text message.
/// New custom alignments can be added with extensions and by overriding the `QuotedChatMessageView.setAvatarAlignment()`.
public struct QuotedAvatarAlignment: RawRepresentable, Equatable {
    /// The avatar will be aligned to the leading, and the message content on the trailing.
    public static let leading = QuotedAvatarAlignment(rawValue: 0)
    /// The avatar will be aligned to the trailing, and the message content on the leading.
    public static let trailing = QuotedAvatarAlignment(rawValue: 1)

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// A view that displays a quoted message.
open class QuotedChatMessageView: _View, ThemeProvider, SwiftUIRepresentable {
    /// The content of the view.
    public struct Content {
        /// The quoted message.
        public let message: ChatMessage
        /// The avatar position in relation with the text message.
        public let avatarAlignment: QuotedAvatarAlignment

        public init(
            message: ChatMessage,
            avatarAlignment: QuotedAvatarAlignment
        ) {
            self.message = message
            self.avatarAlignment = avatarAlignment
        }
    }

    /// The content of this view, composed by the quoted message and the desired avatar alignment.
    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// A Boolean value that checks if all attachments are empty.
    open var isAttachmentsEmpty: Bool {
        guard let content = self.content else { return true }
        return content.message.fileAttachments.isEmpty
            && content.message.imageAttachments.isEmpty
            && content.message.linkAttachments.isEmpty
            && content.message.giphyAttachments.isEmpty
    }

    /// The container view that holds the `authorAvatarView` and the `contentContainerView`.
    open private(set) lazy var containerView: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// The avatar view of the author's quoted message.
    open private(set) lazy var authorAvatarView: ChatAvatarView = components
        .avatarView.init()
        .withoutAutoresizingMaskConstraints

    /// The container view that holds the `textView` and the `attachmentPreview`.
    open private(set) lazy var contentContainerView: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// The `UITextView` that contains quoted message content.
    open private(set) lazy var textView: UITextView = UITextView()
        .withoutAutoresizingMaskConstraints

    /// The attachments preview view if the quoted message has attachments.
    /// The default logic is that the first attachment is displayed on the preview view.
    open private(set) lazy var attachmentPreviewView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    /// The size of the avatar view that belongs to the author of the quoted message.
    open var authorAvatarSize: CGSize { .init(width: 24, height: 24) }

    /// The size of the attachments preview.s
    open var attachmentPreviewSize: CGSize { .init(width: 34, height: 34) }

    override open func setUp() {
        super.setUp()

        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.isScrollEnabled = false
        textView.adjustsFontForContentSizeCategory = true
        textView.isUserInteractionEnabled = false
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        textView.textContainer.maximumNumberOfLines = 6
        textView.textContainer.lineBreakMode = .byTruncatingTail
        textView.textContainer.lineFragmentPadding = .zero
        textView.backgroundColor = .clear
        textView.font = appearance.fonts.subheadline
        textView.textContainerInset = .zero
        textView.textColor = appearance.colorPalette.text

        authorAvatarView.contentMode = .scaleAspectFit

        contentContainerView.layer.cornerRadius = 16
        contentContainerView.layer.borderWidth = 1
        contentContainerView.layer.borderColor = appearance.colorPalette.border.cgColor
        contentContainerView.layer.masksToBounds = true
    }

    override open func setUpLayout() {
        preservesSuperviewLayoutMargins = true

        containerView.isLayoutMarginsRelativeArrangement = true
        containerView.spacing = .auto
        containerView.alignment = .bottom

        contentContainerView.isLayoutMarginsRelativeArrangement = true
        contentContainerView.alignment = .top

        addSubview(containerView)
        containerView.pin(to: layoutMarginsGuide)
        directionalLayoutMargins = .zero

        containerView.addArrangedSubview(authorAvatarView)
        containerView.addArrangedSubview(contentContainerView)
        
        contentContainerView.addArrangedSubview(attachmentPreviewView)
        contentContainerView.addArrangedSubview(textView)

        NSLayoutConstraint.activate([
            authorAvatarView.widthAnchor.pin(equalToConstant: authorAvatarSize.width),
            authorAvatarView.heightAnchor.pin(equalToConstant: authorAvatarSize.height)
        ])

        NSLayoutConstraint.activate([
            attachmentPreviewView.widthAnchor.pin(equalToConstant: attachmentPreviewSize.width),
            attachmentPreviewView.heightAnchor.pin(equalToConstant: attachmentPreviewSize.height)
        ])

        attachmentPreviewView.layer.cornerRadius = attachmentPreviewSize.width / 4
        attachmentPreviewView.layer.masksToBounds = true
    }

    override open func updateContent() {
        guard let message = content?.message else { return }
        guard let avatarAlignment = content?.avatarAlignment else { return }

        textView.text = message.text

        contentContainerView.backgroundColor = message.linkAttachments.isEmpty
            ? appearance.colorPalette.popoverBackground
            : appearance.colorPalette.highlightedAccentBackground1

        setAvatar(imageUrl: message.author.imageURL)
        setAvatarAlignment(avatarAlignment)

        if isAttachmentsEmpty {
            hideAttachmentPreview()
        } else {
            setAttachmentPreview(for: message)
            showAttachmentPreview()
        }
    }

    /// Sets the avatar image from a url or sets the placeholder image if the url is `nil`.
    /// - Parameter imageUrl: The url of the image.
    open func setAvatar(imageUrl: URL?) {
        let placeholder = appearance.images.userAvatarPlaceholder1
        components.imageLoader.loadImage(
            into: authorAvatarView.imageView,
            url: imageUrl,
            imageCDN: components.imageCDN,
            placeholder: placeholder,
            preferredSize: .avatarThumbnailSize
        )
    }

    /// Sets the avatar position in relation of the text bubble.
    /// - Parameter alignment: The avatar alignment of the author of the quoted message.
    open func setAvatarAlignment(_ alignment: QuotedAvatarAlignment) {
        containerView.removeArrangedSubview(authorAvatarView)

        switch alignment {
        case .leading:
            containerView.insertArrangedSubview(authorAvatarView, at: 0)
            contentContainerView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMaxXMaxYCorner
            ]
        case .trailing:
            containerView.addArrangedSubview(authorAvatarView)
            contentContainerView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMinXMaxYCorner
            ]
        default:
            break
        }
    }

    /// Sets the attachment content to the preview view.
    /// Override this function if you want to provide custom logic to present
    /// the attachments preview of the message, or if you want to support your custom attachment.
    /// - Parameter message: The message that contains all the attachments.
    open func setAttachmentPreview(for message: ChatMessage) {
        if let filePayload = message.fileAttachments.first?.payload {
            attachmentPreviewView.contentMode = .scaleAspectFit
            attachmentPreviewView.image = appearance.images.fileIcons[filePayload.file.type] ?? appearance.images.fileFallback
            textView.text = message.text.isEmpty ? filePayload.title : message.text
        } else if let imagePayload = message.imageAttachments.first?.payload {
            attachmentPreviewView.contentMode = .scaleAspectFill
            setAttachmentPreviewImage(url: imagePayload.imageURL)
            textView.text = message.text.isEmpty ? "Photo" : message.text
        } else if let linkPayload = message.linkAttachments.first?.payload {
            attachmentPreviewView.contentMode = .scaleAspectFill
            setAttachmentPreviewImage(url: linkPayload.previewURL)
            textView.text = linkPayload.originalURL.absoluteString
        } else if let giphyPayload = message.giphyAttachments.first?.payload {
            attachmentPreviewView.contentMode = .scaleAspectFill
            setAttachmentPreviewImage(url: giphyPayload.previewURL)
            textView.text = message.text.isEmpty ? "Giphy" : message.text
        }
    }
    
    /// Sets the image from the given URL into `attachmentPreviewView.image`
    /// - Parameter url: The URL from which the image is to be loaded
    open func setAttachmentPreviewImage(url: URL?) {
        components.imageLoader.loadImage(
            into: attachmentPreviewView,
            url: url,
            imageCDN: components.imageCDN
        )
    }

    /// Show the attachment preview view.
    open func showAttachmentPreview() {
        Animate {
            self.attachmentPreviewView.isHidden = false
        }
    }

    /// Hide the attachment preview view.
    open func hideAttachmentPreview() {
        Animate {
            self.attachmentPreviewView.isHidden = true
        }
    }
}
