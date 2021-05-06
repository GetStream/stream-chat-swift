//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The delegate used `GalleryAttachmentViewInjector` to communicate user interactions.
public protocol GalleryContentViewDelegate: ChatMessageContentViewDelegate {
    /// Called when the user taps on one of the image attachments.
    func didTapOnImageAttachment(_ attachment: ChatMessageImageAttachment, at indexPath: IndexPath)
}

public typealias GalleryAttachmentViewInjector = _GalleryAttachmentViewInjector<NoExtraData>

public class _GalleryAttachmentViewInjector<ExtraData: ExtraDataTypes>: _AttachmentViewInjector<ExtraData> {
    public private(set) lazy var galleryView = _ChatMessageImageGallery<ExtraData>()
        .withoutAutoresizingMaskConstraints

    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        contentView.bubbleView?.clipsToBounds = true
        contentView.bubbleContentContainer.insertArrangedSubview(galleryView, at: 0, respectsLayoutMargins: false)

        NSLayoutConstraint.activate([
            galleryView.widthAnchor.pin(equalTo: galleryView.heightAnchor)
        ])
    }
    
    override open func contentViewDidUpdateContent() {
        galleryView.content = imageAttachments
        galleryView.didTapOnAttachment = { [weak self] attachment in
            self?.handleTapOnAttachment(attachment)
        }
    }

    open func handleTapOnAttachment(_ attachment: _ChatMessageAttachment<AttachmentImagePayload>) {
        guard
            let indexPath = contentView.indexPath?()
        else { return }
        (contentView.delegate as? GalleryContentViewDelegate)?.didTapOnImageAttachment(attachment, at: indexPath)
    }
}

private extension _GalleryAttachmentViewInjector {
    var imageAttachments: [ChatMessageImageAttachment] {
        contentView.content?.imageAttachments ?? []
    }
}
