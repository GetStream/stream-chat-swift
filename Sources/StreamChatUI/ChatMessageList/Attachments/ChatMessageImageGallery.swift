//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Gallery view that displays images.
public typealias ChatMessageImageGallery = _ChatMessageImageGallery<NoExtraData>

/// Gallery view that displays images.
open class _ChatMessageImageGallery<ExtraData: ExtraDataTypes>: _View, ThemeProvider {
    /// Content the image gallery should display.
    public var content: [ChatMessageImageAttachment] = [] {
        didSet { updateContentIfNeeded() }
    }
    
    override open var intrinsicContentSize: CGSize { .init(width: .max, height: .max) }

    /// Triggered when an attachment is tapped.
    public var didTapOnAttachment: ((ChatMessageImageAttachment) -> Void)?

    // Previews indices locations:
    // When one image available:
    // -------
    // |     |
    // |  0  |
    // |     |
    // -------
    // When two images available:
    // -------------
    // |     |     |
    // |  0  |  1  |
    // |     |     |
    // -------------
    // When three images available:
    // -------------
    // |     |     |
    // |  0  |     |
    // |     |     |
    // ------|  1  |
    // |     |     |
    // |  2  |     |
    // |     |     |
    // -------------
    // When four and more images available:
    // -------------
    // |     |     |
    // |  0  |  1  |
    // |     |     |
    // -------------
    // |     |     |
    // |  2  |  3  |
    // |     |     |
    // -------------
    /// Previews for images.
    public private(set) lazy var previews = [
        createImagePreview(),
        createImagePreview(),
        createImagePreview(),
        createImagePreview()
    ]

    /// Overlay to be displayed when `content` contains more images than the gallery can display.
    public private(set) lazy var moreImagesOverlay = UILabel()
        .withoutAutoresizingMaskConstraints
    
    /// Container holding all previews.
    public private(set) lazy var previewsContainerView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    /// Left container for previews.
    public private(set) lazy var leftPreviewsContainerView = ContainerStackView()
    
    /// Right container for previews.
    public private(set) lazy var rightPreviewsContainerView = ContainerStackView()

    // MARK: - Overrides

    override open func setUpLayout() {
        previewsContainerView.axis = .horizontal
        previewsContainerView.distribution = .equal
        previewsContainerView.alignment = .fill
        previewsContainerView.spacing = 0
        embed(previewsContainerView)
        
        leftPreviewsContainerView.spacing = 0
        leftPreviewsContainerView.axis = .vertical
        leftPreviewsContainerView.distribution = .equal
        leftPreviewsContainerView.alignment = .fill
        previewsContainerView.addArrangedSubview(leftPreviewsContainerView)
        
        leftPreviewsContainerView.addArrangedSubview(previews[0])
        leftPreviewsContainerView.addArrangedSubview(previews[2])
        
        rightPreviewsContainerView.spacing = 0
        rightPreviewsContainerView.axis = .vertical
        rightPreviewsContainerView.distribution = .equal
        rightPreviewsContainerView.alignment = .fill
        previewsContainerView.addArrangedSubview(rightPreviewsContainerView)
        
        rightPreviewsContainerView.addArrangedSubview(previews[1])
        rightPreviewsContainerView.addArrangedSubview(previews[3])
        
        addSubview(moreImagesOverlay)
        moreImagesOverlay.pin(to: previews[3])
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        moreImagesOverlay.font = appearance.fonts.title
        moreImagesOverlay.adjustsFontForContentSizeCategory = true
        moreImagesOverlay.textAlignment = .center
        moreImagesOverlay.textColor = appearance.colorPalette.staticColorText
        moreImagesOverlay.backgroundColor = appearance.colorPalette.background5
    }

    override open func updateContent() {
        for (index, itemPreview) in previews.enumerated() {
            itemPreview.content = content[safe: index]
            itemPreview.isHidden = itemPreview.content == nil
        }

        // Left and right have the same size if a view is not specified as `isHidden`.
        // Without this, both container views would be forced to be of size zero.
        rightPreviewsContainerView.isHidden = rightPreviewsContainerView.subviews
            .allSatisfy(\.isHidden)

        let otherImagesCount = content.count - previews.count
        moreImagesOverlay.isHidden = otherImagesCount <= 0
        moreImagesOverlay.text = "+\(otherImagesCount)"
    }

    /// Factory method for image previews.
    open func createImagePreview() -> ImagePreview {
        let preview = ImagePreview()
            .withoutAutoresizingMaskConstraints

        preview.didTapOnAttachment = { [weak self] in
            self?.didTapOnAttachment?($0)
        }

        return preview
    }
}
