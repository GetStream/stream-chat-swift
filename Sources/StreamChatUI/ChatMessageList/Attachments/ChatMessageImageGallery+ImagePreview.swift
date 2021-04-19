//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Nuke
import StreamChat
import UIKit

extension _ChatMessageImageGallery {
    open class ImagePreview: _View, UIConfigProvider {
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

        public private(set) lazy var loadingIndicator = uiConfig
            .messageList
            .messageContentSubviews
            .attachmentSubviews
            .loadingIndicator
            .init()
            .withoutAutoresizingMaskConstraints

        public private(set) lazy var uploadingOverlay = uiConfig
            .messageList
            .messageContentSubviews
            .attachmentSubviews
            .imageGalleryItemUploadingOverlay
            .init()
            .withoutAutoresizingMaskConstraints

        // MARK: - Overrides

        override public func defaultAppearance() {
            imageView.backgroundColor = uiConfig.colorPalette.background1
        }

        override open func setUp() {
            super.setUp()
            
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapOnAttachment))
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

            if let url = attachment?.localURL ?? attachment?.imagePreviewURL ?? attachment?.imageURL {
                loadingIndicator.isVisible = true
                imageTask = loadImage(with: url, options: .shared, into: imageView, completion: { [weak self] _ in
                    self?.loadingIndicator.isVisible = false
                    self?.imageTask = nil
                })
            } else {
                loadingIndicator.isVisible = false
                imageView.image = nil
                imageTask = nil
            }

            uploadingOverlay.content = attachment
            uploadingOverlay.isVisible = attachment?.localState != nil
            uploadingOverlay.didTapOnAttachment = { [weak self] in
                self?.handleTapOnAttachment()
            }
        }

        // MARK: - Actions

        @objc open func handleTapOnAttachment() {
            guard let attachment = content else { return }
            didTapOnAttachment?(attachment)
        }

        // MARK: - Init & Deinit

        deinit {
            imageTask?.cancel()
        }
    }
}
