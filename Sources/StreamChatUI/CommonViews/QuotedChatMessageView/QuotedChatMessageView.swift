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
public typealias QuotedChatMessageView = _QuotedChatMessageView<NoExtraData>

/// A view that displays a quoted message.
open class _QuotedChatMessageView<ExtraData: ExtraDataTypes>: _View, ThemeProvider, SwiftUIRepresentable {
    /// The content of the view.
    public struct Content {
        /// The quoted message.
        public let message: _ChatMessage<ExtraData>
        /// The avatar position in relation with the text message.
        public let avatarAlignment: QuotedAvatarAlignment

        public init(
            message: _ChatMessage<ExtraData>,
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

    /// The attachment preview view if the quoted message has an attachment.
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

        contentContainerView.backgroundColor = message.linkAttachments.isEmpty
            ? appearance.colorPalette.popoverBackground
            : appearance.colorPalette.highlightedAccentBackground1

        setAvatar(imageUrl: message.author.imageURL)
        setAvatarAlignment(avatarAlignment)
        setText(message.text)
        setAttachmentPreview(for: message)
    }

    /// Sets the avatar image from a url or sets the placeholder image if the url is `nil`.
    /// - Parameter imageUrl: The url of the image.
    open func setAvatar(imageUrl: URL?) {
        let placeholder = appearance.images.userAvatarPlaceholder1
        authorAvatarView.imageView.loadImage(from: imageUrl, placeholder: placeholder)
    }

    /// Sets the text of the `textView`.
    /// - Parameter text: The content of the text view.
    open func setText(_ text: String) {
        textView.text = text
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

    /// Sets the attachment view or hides it if no attachment found in the message.
    /// - Parameter message: The message owner of the attachment.
    open func setAttachmentPreview(for message: _ChatMessage<ExtraData>) {
        if let filePayload = message.fileAttachments.first?.payload {
            // TODO: Question for designers.
            // I'm not sure if it will be possible to provide specific icon for all file formats
            // so probably we should stick to some generic like other apps do.
            attachmentPreviewView.contentMode = .scaleAspectFit
            attachmentPreviewView.image = appearance.images.fileIcons[filePayload.file.type] ?? appearance.images.fileFallback
            showAttachmentPreview()
        } else if let imagePayload = message.imageAttachments.first?.payload {
            attachmentPreviewView.contentMode = .scaleAspectFill
            attachmentPreviewView.loadImage(from: imagePayload.imageURL)
            showAttachmentPreview()
            // TODO: When we will have attachment examples we will set smth
            // different for different types.
            if message.text.isEmpty {
                textView.text = "Photo"
            }
        } else if let linkPayload = message.linkAttachments.first?.payload {
            attachmentPreviewView.contentMode = .scaleAspectFill
            attachmentPreviewView.loadImage(from: linkPayload.previewURL)
            showAttachmentPreview()
        } else {
            attachmentPreviewView.image = nil
            hideAttachmentPreview()
        }
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
