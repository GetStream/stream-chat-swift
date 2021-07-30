//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// `UICollectionViewCell` for an image item.
public typealias ImageAttachmentGalleryCell = _ImageAttachmentGalleryCell<NoExtraData>

/// `UICollectionViewCell` for an image item.
open class _ImageAttachmentGalleryCell: _GalleryCollectionViewCell<ExtraData> {
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
        
        if let url = imageAttachment?.imageURL {
            imageView.loadImage(
                from: url,
                resize: false,
                components: components
            )
        } else {
            imageView.image = nil
        }
    }
    
    override open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}
