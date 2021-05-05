//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The avatar position in relation with the text message.
struct QuotedAvatarAlignment: Equatable {
    /// The avatar will be aligned to the left, and the message content on the right.
    static let left = QuotedAvatarAlignment(rawValue: 0)
    /// The avatar will be aligned to the right, and the message content on the left.
    static let right = QuotedAvatarAlignment(rawValue: 1)

    private let rawValue: Int
}

/// A view that displays a quoted message.
public typealias QuotedChatMessageView = _QuotedChatMessageView<NoExtraData>

/// A view that displays a quoted message.
open class _QuotedChatMessageView<ExtraData: ExtraDataTypes>: _View, ThemeProvider {
    /// The content of the view.
    public struct Content {
        /// The quoted message.
        let message: _ChatMessage<ExtraData>?
        /// The avatar position in relation with the text message.
        let avatarAlignment: QuotedAvatarAlignment
    }

    /// The content of this view, composed by the quoted message and the desired avatar alignment.
    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The container view that holds the `authorAvatarView` and the `contentContainerView`.
    public private(set) lazy var containerView: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// The avatar view of the author's quoted message.
    public private(set) lazy var authorAvatarView: ChatAvatarView = components
        .avatarView.init()
        .withoutAutoresizingMaskConstraints

    /// The container view that holds the `textView` and the `attachmentPreview`.
    public private(set) lazy var contentContainerView: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// The `UITextView` that contains quoted message content.
    public private(set) lazy var textView: UITextView = UITextView()
        .withoutAutoresizingMaskConstraints

    /// The attachment preview view if the quoted message has an attachment.
    public private(set) lazy var attachmentPreviewView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

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

    override open func updateContent() {
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

private extension _QuotedChatMessageView {
    /// Sets the avatar image from a url or sets the placeholder image if the url is `nil`.
    /// - Parameter imageUrl: The url of the image.
    func setAvatar(imageUrl: URL?) {
        let placeholder = appearance.images.userAvatarPlaceholder1
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
    func showAttachmentPreview() {
        Animate {
            self.attachmentPreviewView.isHidden = false
        }
    }

    /// Hide the attachment preview view.
    func hideAttachmentPreview() {
        Animate {
            self.attachmentPreviewView.isHidden = true
        }
    }
}
