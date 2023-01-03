//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// `UICollectionViewCell` for an image item.
open class ImageAttachmentGalleryCell: GalleryCollectionViewCell {
    open class var reuseId: String { String(describing: self) }

    /// A view that displays an image.
    open private(set) lazy var imageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    override open func setUp() {
        super.setUp()

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
    }

    override open func setUpLayout() {
        super.setUpLayout()

        scrollView.addSubview(imageView)
        imageView.pin(anchors: [.height, .width], to: contentView)
    }

    override open func updateContent() {
        super.updateContent()

        let imageAttachment = content?.attachment(payloadType: ImageAttachmentPayload.self)

        components.imageLoader.loadImage(
            into: imageView,
            from: imageAttachment?.payload,
            maxResolutionInPixels: components.imageAttachmentMaxPixels
        )
    }

    override open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}
