//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
public typealias GalleryAttachmentViewInjector = _GalleryAttachmentViewInjector<NoExtraData>

/// The type used to show an media gallery in `ChatMessageContentView`.
open class _GalleryAttachmentViewInjector<ExtraData: ExtraDataTypes>: _AttachmentViewInjector<ExtraData> {
    /// A gallery which shows attachment previews.
    open private(set) lazy var galleryView: _ChatMessageGalleryView<ExtraData> = contentView
        .components
        .galleryView.init()
        .withoutAutoresizingMaskConstraints

    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        super.contentViewDidLayout(options: options)
        
        contentView.bubbleView?.clipsToBounds = true
        contentView.bubbleContentContainer.insertArrangedSubview(galleryView, at: 0, respectsLayoutMargins: false)

        NSLayoutConstraint.activate([
            galleryView.widthAnchor.pin(equalTo: galleryView.heightAnchor)
        ])
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

private extension _GalleryAttachmentViewInjector {
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
