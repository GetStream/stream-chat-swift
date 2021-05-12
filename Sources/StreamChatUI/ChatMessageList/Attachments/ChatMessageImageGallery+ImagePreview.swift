//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Nuke
import StreamChat
import UIKit

/// Propeties necessary for image to be previewed.
public protocol ImagePreviewable {
    /// Content containing image attachment.
    var content: ChatMessageImageAttachment? { get }
    /// `UIImageView` that is displayed the image preview.
    var imageView: UIImageView { get }
}

extension _ChatMessageImageGallery {
    open class ImagePreview: _View, ThemeProvider, ImagePreviewable {
        public var content: ChatMessageImageAttachment? {
            didSet { updateContentIfNeeded() }
        }

        public var didTapOnAttachment: ((ChatMessageImageAttachment) -> Void)?
        
        private var imageTask: ImageTask? {
            didSet { oldValue?.cancel() }
        }

        // MARK: - Subviews

        public private(set) lazy var imageView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.layer.masksToBounds = true
            return imageView.withoutAutoresizingMaskConstraints
        }()

        public private(set) lazy var loadingIndicator = components
            .messageList
            .messageContentSubviews
            .attachmentSubviews
            .loadingIndicator
            .init()
            .withoutAutoresizingMaskConstraints

        public private(set) lazy var uploadingOverlay = components
            .messageList
            .messageContentSubviews
            .attachmentSubviews
            .imageGalleryItemUploadingOverlay
            .init()
            .withoutAutoresizingMaskConstraints

        // MARK: - Overrides

        override open func setUpAppearance() {
            super.setUpAppearance()
            imageView.backgroundColor = appearance.colorPalette.background1
        }

        override open func setUp() {
            super.setUp()
            
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnAttachment(_:)))
            addGestureRecognizer(tapRecognizer)
        }

        override open func setUpLayout() {
            embed(imageView)
            embed(uploadingOverlay)

            addSubview(loadingIndicator)
            loadingIndicator.centerYAnchor.pin(equalTo: centerYAnchor).isActive = true
            loadingIndicator.centerXAnchor.pin(equalTo: centerXAnchor).isActive = true
        }

        override open func updateContent() {
            let attachment = content

            loadingIndicator.isVisible = true
            imageView.layoutIfNeeded()
            imageTask = imageView
                .loadImage(from: attachment?.payload?.imagePreviewURL, resizeAutomatically: false) { [weak self] _ in
                    self?.loadingIndicator.isVisible = false
                    self?.imageTask = nil
                }

            uploadingOverlay.content = content
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
