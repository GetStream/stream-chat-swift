//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Nuke
import StreamChat
import UIKit

extension ChatMessageImageGallery {
    open class ImagePreview: View, UIConfigProvider {
        public var content: AttachmentListViewData<ExtraData>.ItemData? {
            didSet { updateContentIfNeeded() }
        }
        
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
            imageView.backgroundColor = uiConfig.colorPalette.galleryImageBackground
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
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        }

        override open func updateContent() {
            let attachment = content?.attachment

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

            uploadingOverlay.content = content
            uploadingOverlay.isVisible = attachment?.localState != nil
        }

        // MARK: - Actions

        @objc open func didTapOnAttachment(_ recognizer: UITapGestureRecognizer) {
            content?.didTapOnAttachment()
        }

        // MARK: - Init & Deinit

        deinit {
            imageTask?.cancel()
        }
    }
}
