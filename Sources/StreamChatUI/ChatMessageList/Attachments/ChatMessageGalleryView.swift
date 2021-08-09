//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Gallery view that displays images and video previews.
open class ChatMessageGalleryView: _View, ThemeProvider {
    /// Content the gallery should display.
    public var content: [UIView] = [] {
        didSet { updateContentIfNeeded() }
    }
    
    // Previews indices locations:
    // When one item available:
    // -------
    // |     |
    // |  0  |
    // |     |
    // -------
    // When two items available:
    // -------------
    // |     |     |
    // |  0  |  1  |
    // |     |     |
    // -------------
    // When three items available:
    // -------------
    // |     |     |
    // |  0  |     |
    // |     |     |
    // ------|  1  |
    // |     |     |
    // |  2  |     |
    // |     |     |
    // -------------
    // When four and more items available:
    // -------------
    // |     |     |
    // |  0  |  1  |
    // |     |     |
    // -------------
    // |     |     |
    // |  2  |  3  |
    // |     |     |
    // -------------
    /// The spots gallery items takes.
    public private(set) lazy var itemSpots = [
        UIView().withoutAutoresizingMaskConstraints,
        UIView().withoutAutoresizingMaskConstraints,
        UIView().withoutAutoresizingMaskConstraints,
        UIView().withoutAutoresizingMaskConstraints
    ]

    /// Overlay to be displayed when `content` contains more items than the gallery can display.
    public private(set) lazy var moreItemsOverlay = UILabel()
        .withoutAutoresizingMaskConstraints
    
    /// Container holding all previews.
    public private(set) lazy var previewsContainerView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    /// Left container for previews.
    public private(set) lazy var leftPreviewsContainerView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    /// Right container for previews.
    public private(set) lazy var rightPreviewsContainerView = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    // MARK: - Overrides

    override open func setUpLayout() {
        super.setUpLayout()
        
        previewsContainerView.axis = .horizontal
        previewsContainerView.distribution = .equal
        previewsContainerView.alignment = .fill
        previewsContainerView.spacing = 2
        previewsContainerView.isLayoutMarginsRelativeArrangement = true
        previewsContainerView.directionalLayoutMargins = .init(top: 2, leading: 2, bottom: 2, trailing: 2)
        embed(previewsContainerView)
        
        leftPreviewsContainerView.spacing = 2
        leftPreviewsContainerView.axis = .vertical
        leftPreviewsContainerView.distribution = .equal
        leftPreviewsContainerView.alignment = .fill
        previewsContainerView.addArrangedSubview(leftPreviewsContainerView)
        
        leftPreviewsContainerView.addArrangedSubview(itemSpots[0])
        leftPreviewsContainerView.addArrangedSubview(itemSpots[2])
        
        rightPreviewsContainerView.spacing = 2
        rightPreviewsContainerView.axis = .vertical
        rightPreviewsContainerView.distribution = .equal
        rightPreviewsContainerView.alignment = .fill
        previewsContainerView.addArrangedSubview(rightPreviewsContainerView)
        
        rightPreviewsContainerView.addArrangedSubview(itemSpots[1])
        rightPreviewsContainerView.addArrangedSubview(itemSpots[3])
        
        addSubview(moreItemsOverlay)
        moreItemsOverlay.pin(to: itemSpots[3])
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        
        moreItemsOverlay.font = appearance.fonts.title
        moreItemsOverlay.adjustsFontForContentSizeCategory = true
        moreItemsOverlay.textAlignment = .center
        moreItemsOverlay.textColor = appearance.colorPalette.staticColorText
        moreItemsOverlay.backgroundColor = appearance.colorPalette.background5
    }

    override open func updateContent() {
        super.updateContent()
        
        // Clear all spots
        itemSpots
            .flatMap(\.subviews)
            .forEach { $0.removeFromSuperview() }
        
        // Prevents layout issue. Can be removed when CIS-981 is fixed.
        guard !content.isEmpty else {
            previewsContainerView.isHidden = true
            return
        }
        
        // Add previews to the spots
        if content.count == 3 {
            itemSpots[0].embed(content[0])
            itemSpots[1].embed(content[1])
            itemSpots[3].embed(content[2])
        } else {
            zip(itemSpots, content).forEach { $0.embed($1) }
        }
        
        // Show taken spots, hide empty ones
        itemSpots.forEach { spot in
            spot.isHidden = spot.subviews.isEmpty
        }
        
        rightPreviewsContainerView.isHidden = rightPreviewsContainerView.subviews
            .allSatisfy(\.isHidden)
        leftPreviewsContainerView.isHidden = leftPreviewsContainerView.subviews
            .allSatisfy(\.isHidden)
        previewsContainerView.isHidden = previewsContainerView.subviews
            .allSatisfy(\.isHidden)

        let notShownPreviewsCount = content.count - itemSpots.count
        moreItemsOverlay.text = notShownPreviewsCount > 0 ? "+\(notShownPreviewsCount)" : nil
        moreItemsOverlay.isHidden = moreItemsOverlay.text == nil
    }
}
