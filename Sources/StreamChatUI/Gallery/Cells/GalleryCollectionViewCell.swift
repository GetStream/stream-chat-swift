//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// `UICollectionViewCell` for a gallery item.
open class GalleryCollectionViewCell: _CollectionViewCell, UIScrollViewDelegate, ComponentsProvider {
    /// Triggered when the scroll view is single tapped.
    open var didTapOnce: (() -> Void)?
    
    /// The cell content.
    open var content: AnyChatMessageAttachment? {
        didSet { updateContentIfNeeded() }
    }
    
    /// `UIScrollView` to enable zooming the content.
    public private(set) lazy var scrollView = UIScrollView()
        .withoutAutoresizingMaskConstraints
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
    }
    
    override open func setUp() {
        super.setUp()
        
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 5
        
        let doubleTapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleDoubleTapOnScrollView)
        )
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGestureRecognizer)
        
        let singleTapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleSingleTapOnScrollView)
        )
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        scrollView.addGestureRecognizer(singleTapGestureRecognizer)
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        contentView.embed(scrollView)
    }
    
    /// Triggered when scroll view is double tapped.
    @objc open func handleDoubleTapOnScrollView() {
        if scrollView.zoomScale != scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            scrollView.setZoomScale(scrollView.maximumZoomScale / 2, animated: true)
        }
    }
    
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        nil
    }
    
    /// Triggered when scroll view is single tapped.
    @objc open func handleSingleTapOnScrollView() {
        didTapOnce?()
    }
    
    override open func prepareForReuse() {
        super.prepareForReuse()
        
        didTapOnce = nil
        content = nil
    }
}
