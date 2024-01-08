//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVKit
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
        /// The channel which the message belongs to.
        public let channel: ChatChannel?

        public init(
            message: ChatMessage,
            avatarAlignment: QuotedAvatarAlignment,
            channel: ChatChannel? = nil
        ) {
            self.message = message
            self.avatarAlignment = avatarAlignment
            self.channel = channel
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
        return content.message.allAttachments.isEmpty
    }

    /// The container view that holds the `authorAvatarView` and the `contentContainerView`.
    open private(set) lazy var containerView: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "containerView")

    /// The avatar view of the author's quoted message.
    open private(set) lazy var authorAvatarView: ChatAvatarView = components
        .avatarView.init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "authorAvatarView")

    /// The container view that holds the `textView` and the `attachmentPreview`.
    open private(set) lazy var contentContainerView: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "contentContainerView")

    /// The `UITextView` that contains quoted message content.
    open private(set) lazy var textView: UITextView = UITextView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "textView")

    /// The attachments preview view if the quoted message has attachments.
    /// The default logic is that the first attachment is displayed on the preview view.
    open private(set) lazy var attachmentPreviewView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "attachmentPreviewView")

    open private(set) lazy var voiceRecordingAttachmentQuotedPreview: VoiceRecordingAttachmentQuotedPreview =
        components
            .voiceRecordingAttachmentQuotedPreview
            .init()
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

        embed(containerView)

        containerView.addArrangedSubview(authorAvatarView)
        containerView.addArrangedSubview(contentContainerView)

        contentContainerView.addArrangedSubview(attachmentPreviewView)
        contentContainerView.addArrangedSubview(voiceRecordingAttachmentQuotedPreview)
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

        voiceRecordingAttachmentQuotedPreview.isHidden = true
    }

    override open func updateContent() {
        guard let message = content?.message else { return }
        guard let avatarAlignment = content?.avatarAlignment else { return }

        contentContainerView.backgroundColor = message.linkAttachments.isEmpty
            ? appearance.colorPalette.popoverBackground
            : appearance.colorPalette.highlightedAccentBackground1
        
        textView.text = message.text
        setAvatar(imageUrl: message.author.imageURL)
        setAvatarAlignment(avatarAlignment)

        if isAttachmentsEmpty {
            hideAttachmentPreview()
        } else {
            setAttachmentPreview(for: message)
            showAttachmentPreview()
        }

        if let currentUserLang = content?.channel?.membership?.language,
           let translatedText = content?.message.translatedText(for: currentUserLang) {
            textView.text = translatedText
        }
    }

    /// Sets the avatar image from a url or sets the placeholder image if the url is `nil`.
    /// - Parameter imageUrl: The url of the image.
    open func setAvatar(imageUrl: URL?) {
        let placeholder = appearance.images.userAvatarPlaceholder1
        components.imageLoader.loadImage(
            into: authorAvatarView.imageView,
            from: imageUrl,
            with: ImageLoaderOptions(
                resize: .init(components.avatarThumbnailSize),
                placeholder: placeholder
            )
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
            textView.text = message.text.isEmpty ? L10n.Composer.QuotedMessage.photo : message.text
        } else if let linkPayload = message.linkAttachments.first?.payload {
            attachmentPreviewView.contentMode = .scaleAspectFill
            setAttachmentPreviewImage(url: linkPayload.previewURL)
            textView.text = linkPayload.originalURL.absoluteString
        } else if let giphyPayload = message.giphyAttachments.first?.payload {
            attachmentPreviewView.contentMode = .scaleAspectFill
            setAttachmentPreviewImage(url: giphyPayload.previewURL)
            textView.text = message.text.isEmpty ? L10n.Composer.QuotedMessage.giphy : message.text
        } else if let videoPayload = message.videoAttachments.first?.payload {
            attachmentPreviewView.contentMode = .scaleAspectFill
            textView.text = message.text.isEmpty ? videoPayload.title : message.text
            if let thumbnailURL = videoPayload.thumbnailURL {
                setVideoAttachmentThumbnail(url: thumbnailURL)
            } else {
                setVideoAttachmentPreviewImage(url: videoPayload.videoURL)
            }
        } else if let voiceRecordingPayload = message.voiceRecordingAttachments.first?.payload {
            voiceRecordingAttachmentQuotedPreview.content = .init(
                title: voiceRecordingPayload.title ?? message.text,
                size: voiceRecordingPayload.file.size,
                duration: voiceRecordingPayload.duration ?? 0,
                audioAssetURL: voiceRecordingPayload.voiceRecordingURL
            )
            textView.text = nil
        } else {
            setUnsupportedAttachmentPreview(for: message)
        }
    }

    /// Sets the image from the given URL into `attachmentPreviewView.image`
    /// - Parameter url: The URL from which the image is to be loaded
    open func setAttachmentPreviewImage(url: URL?) {
        components.imageLoader.loadImage(
            into: attachmentPreviewView,
            from: url,
            with: ImageLoaderOptions(resize: .init(attachmentPreviewSize))
        )
    }

    /// Set the image from the given URL into `attachmentPreviewImage.image`
    /// - Parameter url: The URL of the thumbnail
    open func setVideoAttachmentThumbnail(url: URL) {
        components.imageLoader.downloadImage(with: .init(url: url, options: ImageDownloadOptions())) { [weak self] result in
            switch result {
            case let .success(preview):
                self?.attachmentPreviewView.image = preview
            case .failure:
                self?.attachmentPreviewView.image = nil
            }
        }
    }

    /// Set the image from the given URL into `attachmentPreviewImage.image`
    /// - Parameter url: The URL from which to generate the image on the video
    open func setVideoAttachmentPreviewImage(url: URL?) {
        guard let url = url else { return }

        components.videoLoader.loadPreviewForVideo(at: url) { [weak self] in
            switch $0 {
            case let .success(preview):
                self?.attachmentPreviewView.image = preview
            case let .failure(error):
                self?.attachmentPreviewView.image = nil
                log.error("This \(error) received for processing Video Preview image.")
            }
        }
    }

    /// Show the attachment preview view.
    open func showAttachmentPreview() {
        let containsVoiceRecording = content?.message.voiceRecordingAttachments.isEmpty == false
        Animate {
            self.voiceRecordingAttachmentQuotedPreview.isHidden = !containsVoiceRecording
            self.attachmentPreviewView.isHidden = containsVoiceRecording
        }
    }

    /// Hide the attachment preview view.
    open func hideAttachmentPreview() {
        Animate {
            self.attachmentPreviewView.isHidden = true
            self.voiceRecordingAttachmentQuotedPreview.isHidden = true
        }
    }

    /// Sets the unsupported attachment content to the preview view.
    open func setUnsupportedAttachmentPreview(for message: ChatMessage) {
        attachmentPreviewView.contentMode = .scaleAspectFit
        attachmentPreviewView.image = appearance.images.fileFallback
        textView.text = message.text.isEmpty ? L10n.Message.unsupportedAttachment : message.text
    }
}
