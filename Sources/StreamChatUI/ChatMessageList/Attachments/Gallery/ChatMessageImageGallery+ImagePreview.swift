//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The type preview should conform to in order the gallery can be shown from it.
public protocol GalleryItemPreview {
    /// Attachment identifier.
    var attachmentId: AttachmentId? { get }

    /// `UIImageView` that is displayed the attachment preview.
    var imageView: UIImageView { get }
}

extension ChatMessageGalleryView {
    @objc(ChatMessageGalleryViewImagePreview)
    open class ImagePreview: _View, ThemeProvider, GalleryItemPreview {
        public var content: ChatMessageImageAttachment? {
            didSet { updateContentIfNeeded() }
        }

        public var attachmentId: AttachmentId? {
            content?.id
        }

        public var didTapOnAttachment: ((ChatMessageImageAttachment) -> Void)?
        public var didTapOnUploadingActionButton: ((ChatMessageImageAttachment) -> Void)?

        private var imageTask: Cancellable? {
            didSet { oldValue?.cancel() }
        }

        // MARK: - Subviews

        public private(set) lazy var imageView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.layer.masksToBounds = true
            return imageView
                .withoutAutoresizingMaskConstraints
                .withAccessibilityIdentifier(identifier: "imageView")
        }()

        public private(set) lazy var loadingIndicator = components
            .loadingIndicator
            .init()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "loadingIndicator")

        public private(set) lazy var uploadingOverlay = components
            .uploadingOverlayView
            .init()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "uploadingOverlay")

        // MARK: - Overrides

        override open func setUpAppearance() {
            super.setUpAppearance()
            imageView.backgroundColor = appearance.colorPalette.background1
        }

        override open func setUp() {
            super.setUp()

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnAttachment(_:)))
            addGestureRecognizer(tapRecognizer)

            uploadingOverlay.didTapActionButton = { [weak self] in
                guard let self = self, let attachment = self.content else { return }

                self.didTapOnUploadingActionButton?(attachment)
            }
        }

        override open func setUpLayout() {
            embed(imageView)
            embed(uploadingOverlay)

            addSubview(loadingIndicator)
            loadingIndicator.centerYAnchor.pin(equalTo: centerYAnchor).isActive = true
            loadingIndicator.centerXAnchor.pin(equalTo: centerXAnchor).isActive = true
        }

        override open func updateContent() {
            super.updateContent()

            let attachment = content

            loadingIndicator.isVisible = true
            imageTask = components.imageLoader.loadImage(
                into: imageView,
                from: attachment?.payload,
                maxResolutionInPixels: components.imageAttachmentMaxPixels
            ) { [weak self] _ in
                self?.loadingIndicator.isVisible = false
                self?.imageTask = nil
            }

            uploadingOverlay.content = content?.uploadingState
            uploadingOverlay.isVisible = attachment?.uploadingState != nil
        }

        // MARK: - Actions

        @objc open func didTapOnAttachment(_ recognizer: UITapGestureRecognizer) {
            guard let attachment = content else { return }
            didTapOnAttachment?(attachment)
        }

        // MARK: - Init & Deinit

        deinit {
            imageTask?.cancel()
        }
    }
}
