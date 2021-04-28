//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// `UICollectionViewCell` for a single image.
open class ImageCollectionViewCell: _CollectionViewCell, UIScrollViewDelegate {
    /// Reuse identifier of this cell.
    open class var reuseId: String { String(describing: self) }
    
    /// Content of this view.
    open var content: ChatMessageDefaultAttachment! {
        didSet { updateContentIfNeeded() }
    }
    
    /// Triggered when the underlying image is single tapped.
    open var imageSingleTapped: (() -> Void)?
    
    /// Image view showing the single image.
    public private(set) lazy var imageView = UIImageView()
        .withoutAutoresizingMaskConstraints
    
    /// `UIScrollView` to enable zooming the image.
    public private(set) lazy var imageScrollView = UIScrollView()
        .withoutAutoresizingMaskConstraints
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
    }
    
    override open func setUp() {
        super.setUp()
        
        imageScrollView.delegate = self
        imageScrollView.minimumZoomScale = 1
        imageScrollView.maximumZoomScale = 5
        
        let doubleTapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(imageScrollViewDoubleTapped)
        )
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        imageScrollView.addGestureRecognizer(doubleTapGestureRecognizer)
        
        let singleTapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(imageScrollViewSingleTapped)
        )
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        imageScrollView.addGestureRecognizer(singleTapGestureRecognizer)
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        contentView.embed(imageScrollView)
        imageScrollView.embed(imageView)
        imageView.pin(anchors: [.height, .width], to: contentView)
    }
    
    override open func updateContent() {
        super.updateContent()

        imageView.loadImage(from: content.imageURL, resizeAutomatically: false)
    }
    
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
    
    /// Triggered when image scroll view is double tapped.
    @objc
    open func imageScrollViewDoubleTapped() {
        if imageScrollView.zoomScale != imageScrollView.minimumZoomScale {
            imageScrollView.setZoomScale(imageScrollView.minimumZoomScale, animated: true)
        } else {
            imageScrollView.setZoomScale(imageScrollView.maximumZoomScale / 2, animated: true)
        }
    }
    
    /// Triggered when image scroll view is single tapped.
    @objc
    open func imageScrollViewSingleTapped() {
        imageSingleTapped?()
    }
}
