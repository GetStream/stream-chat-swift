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
    /// A custom `UIImageView` view that always returns max. `intrinsicContentSize`.
    private class EagerImageView: UIImageView {
        override var intrinsicContentSize: CGSize { .init(width: .max, height: .max) }
    }

    open lazy var galleryView: UIImageView = {
        let imageView = EagerImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnImage)))
        imageView.clipsToBounds = true
        return imageView.withoutAutoresizingMaskConstraints
    }()

    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        contentView.bubbleView?.clipsToBounds = true
        contentView.bubbleContentContainer.insertArrangedSubview(galleryView, at: 0, respectsLayoutMargins: false)

        NSLayoutConstraint.activate([
            galleryView.widthAnchor.pin(equalTo: galleryView.heightAnchor)
        ])
    }

    override open func contentViewDidUpdateContent() {
        galleryView.loadImage(from: imageAttachments.first?.imageURL)
    }

    @objc open func handleTapOnImage() {
        guard let attachment = imageAttachments.first,
              let indexPath = contentView.indexPath?()
        else { return }
        (contentView.delegate as? GalleryContentViewDelegate)?.didTapOnImageAttachment(attachment, at: indexPath)
    }
}

private extension _GalleryAttachmentViewInjector {
    var imageAttachments: [ChatMessageImageAttachment] {
        contentView.content?.attachments.compactMap { $0 as? ChatMessageImageAttachment } ?? []
    }
}
