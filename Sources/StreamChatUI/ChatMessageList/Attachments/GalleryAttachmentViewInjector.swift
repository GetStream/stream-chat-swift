//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The delegate used `GalleryAttachmentViewInjector` to communicate user interactions.
public protocol GalleryContentViewDelegate: ChatMessageContentViewDelegate {
    /// Called when the user taps on one of the attachment previews.
    func galleryMessageContentView(
        at indexPath: IndexPath?,
        didTapAttachmentPreview attachmentId: AttachmentId,
        previews: [GalleryItemPreview]
    )

    /// Called when action button is clicked for uploading attachment.
    func galleryMessageContentView(
        at indexPath: IndexPath?,
        didTakeActionOnUploadingAttachment attachmentId: AttachmentId
    )
}

/// The type used to show an media gallery in `ChatMessageContentView`.
open class GalleryAttachmentViewInjector: AttachmentViewInjector {
    /// A gallery which shows attachment previews.
    open private(set) lazy var galleryView: ChatMessageGalleryView = contentView
        .components
        .galleryView.init()
        .withoutAutoresizingMaskConstraints

    /// A gallery view width * height ratio.
    ///
    /// If `nil` is returned, aspect ratio will not be applied and gallery view will
    /// aspect ratio will depend on internal constraints.
    ///
    /// Returns `1.32` by default.
    open var galleryViewAspectRatio: CGFloat? { 1.32 }

    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        super.contentViewDidLayout(options: options)

        contentView.bubbleView?.clipsToBounds = true
        contentView.bubbleContentContainer.insertArrangedSubview(galleryView, at: 0, respectsLayoutMargins: false)

        // We need to apply corners to the left and right containers because the previewsContainerView
        // is applying extra layout margins and the rounded corners wouldn't match the margins.
        let leftCorners: CACornerMask = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
        galleryView.leftPreviewsContainerView.layer.maskedCorners = options.roundedCorners.intersection(leftCorners)
        galleryView.leftPreviewsContainerView.layer.cornerRadius = 16
        galleryView.leftPreviewsContainerView.layer.masksToBounds = true

        let rightCorners: CACornerMask = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        galleryView.rightPreviewsContainerView.layer.maskedCorners = options.roundedCorners.intersection(rightCorners)
        galleryView.rightPreviewsContainerView.layer.cornerRadius = 16
        galleryView.rightPreviewsContainerView.layer.masksToBounds = true

        if let ratio = galleryViewAspectRatio {
            galleryView
                .widthAnchor
                .pin(equalTo: galleryView.heightAnchor, multiplier: ratio)
                .isActive = true
        }
    }

    override open func contentViewDidUpdateContent() {
        super.contentViewDidUpdateContent()

        let videos = attachments(payloadType: VideoAttachmentPayload.self)
        let images = attachments(payloadType: ImageAttachmentPayload.self)
        galleryView.content = videos.map(preview) + images.map(preview)
    }

    /// Is invoked when attachment preview is tapped.
    /// - Parameter id: Attachment identifier.
    open func handleTapOnAttachment(with id: AttachmentId) {
        delegate?.galleryMessageContentView(
            at: contentView.indexPath?(),
            didTapAttachmentPreview: id,
            previews: galleryView.content.compactMap { $0 as? GalleryItemPreview }
        )
    }

    /// Is invoked when action button on attachment uploading overlay is tapped.
    /// - Parameter id: Attachment identifier.
    open func handleUploadingAttachmentAction(_ attachmentId: AttachmentId) {
        delegate?.galleryMessageContentView(
            at: contentView.indexPath?(),
            didTakeActionOnUploadingAttachment: attachmentId
        )
    }
}

private extension GalleryAttachmentViewInjector {
    var delegate: GalleryContentViewDelegate? {
        contentView.delegate as? GalleryContentViewDelegate
    }

    func preview(for videoAttachment: ChatMessageVideoAttachment) -> UIView {
        let preview = contentView
            .components
            .videoAttachmentGalleryPreview
            .init()
            .withoutAutoresizingMaskConstraints

        preview.didTapOnAttachment = { [weak self] in
            self?.handleTapOnAttachment(with: $0.id)
        }

        preview.didTapOnUploadingActionButton = { [weak self] in
            self?.handleUploadingAttachmentAction($0.id)
        }

        preview.content = videoAttachment

        return preview
    }

    func preview(for imageAttachment: ChatMessageImageAttachment) -> UIView {
        let preview = contentView
            .components
            .imageAttachmentGalleryPreview
            .init()
            .withoutAutoresizingMaskConstraints

        preview.didTapOnAttachment = { [weak self] in
            self?.handleTapOnAttachment(with: $0.id)
        }

        preview.didTapOnUploadingActionButton = { [weak self] in
            self?.handleUploadingAttachmentAction($0.id)
        }

        preview.content = imageAttachment

        return preview
    }
}
