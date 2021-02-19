//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

/// A `UICollectionViewCell` subclass that shows channel information.
internal typealias ChatChannelListCollectionViewCell = _ChatChannelListCollectionViewCell<NoExtraData>

/// A `UICollectionViewCell` subclass that shows channel information.
internal class _ChatChannelListCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell,
    UIConfigProvider {
    /// The `ChatChannelListItemView` instance used as content view.
    internal private(set) lazy var itemView: _ChatChannelListItemView<ExtraData> = uiConfig
        .channelList
        .itemView
        .init()
        .withoutAutoresizingMaskConstraints

    /// The `SwipeableView` instance which is used for revealing buttons when cell is swiped.
    internal private(set) lazy var swipeableView: _SwipeableView<ExtraData> = uiConfig
        .channelList
        .swipeableView.init()
        .withoutAutoresizingMaskConstraints

    override internal func prepareForReuse() {
        super.prepareForReuse()
        swipeableView.close()
    }

    override internal var isHighlighted: Bool {
        didSet {
            itemView.backgroundColor = isHighlighted ? uiConfig.colorPalette.highlightedBackground :
                uiConfig.colorPalette.background
        }
    }

    override internal func setUp() {
        super.setUp()
        contentView.addGestureRecognizer(swipeableView.panGestureRecognizer)
    }

    override internal func setUpLayout() {
        super.setUpLayout()

        contentView.addSubview(swipeableView)
        NSLayoutConstraint.activate([
            swipeableView.leadingAnchor.pin(equalTo: contentView.leadingAnchor),
            swipeableView.topAnchor.pin(equalTo: contentView.topAnchor),
            swipeableView.trailingAnchor.pin(equalTo: contentView.trailingAnchor),
            swipeableView.bottomAnchor.pin(equalTo: contentView.bottomAnchor),
            swipeableView.heightAnchor.pin(equalTo: contentView.heightAnchor)
        ])

        contentView.addSubview(itemView)
        NSLayoutConstraint.activate([
            itemView.widthAnchor.pin(equalTo: contentView.widthAnchor),
            itemView.topAnchor.pin(equalTo: contentView.topAnchor),
            itemView.trailingAnchor.pin(equalTo: swipeableView.contentTrailingAnchor),
            itemView.bottomAnchor.pin(equalTo: contentView.bottomAnchor)
        ])
    }

    override open func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        let preferredAttributes = super.preferredLayoutAttributesFitting(layoutAttributes)

        let targetSize = CGSize(
            width: layoutAttributes.frame.width,
            height: UIView.layoutFittingCompressedSize.height
        )

        preferredAttributes.frame.size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        return preferredAttributes
    }
}
