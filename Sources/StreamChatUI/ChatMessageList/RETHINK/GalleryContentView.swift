//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

protocol GalleryContentViewDelegate: MessageContentViewDelegate {
    func didTapOnImageAttachment(_ attachment: ChatMessageImageAttachment, at indexPath: IndexPath)
}

class GalleryContentView<ExtraData: ExtraDataTypes>: MessageContentView<ExtraData> {
    lazy var galleryView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnImage)))
        return imageView.withoutAutoresizingMaskConstraints
    }()

    override func layout(options: ChatMessageLayoutOptions) {
        super.layout(options: options)

        bubbleContentContainer.insertArrangedSubview(galleryView, at: 0)
        NSLayoutConstraint.activate([
            galleryView.widthAnchor.pin(equalTo: galleryView.heightAnchor),
            galleryView.widthAnchor.pin(equalTo: mainContainer.widthAnchor)
                .with(priority: .streamLow)
        ])
    }

    override func updateContent() {
        super.updateContent()

        galleryView.loadImage(from: imageAttachments.first?.imageURL)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    @objc func handleTapOnImage() {
        guard let attachment = imageAttachments.first, let indexPath = indexPath else { return }
        (delegate as? GalleryContentViewDelegate)?.didTapOnImageAttachment(attachment, at: indexPath)
    }
}

private extension GalleryContentView {
    var imageAttachments: [ChatMessageImageAttachment] {
        content?.attachments.compactMap { $0 as? ChatMessageImageAttachment } ?? []
    }
}
