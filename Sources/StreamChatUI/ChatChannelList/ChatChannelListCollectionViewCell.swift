//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

/// A `UICollectionViewCell` subclass that shows channel information.
internal typealias ChatChannelListCollectionViewCell = _ChatChannelListCollectionViewCell<NoExtraData>

/// A `UICollectionViewCell` subclass that shows channel information.
internal class _ChatChannelListCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell, UIConfigProvider {
    /// The `ChatChannelListItemView` instance used as content view.
    internal private(set) lazy var channelView: _ChatChannelListItemView<ExtraData> = uiConfig.channelList.channelListItemView.init()

    override internal func prepareForReuse() {
        super.prepareForReuse()
        channelView.trailingConstraint?.constant = 0
    }

    override internal var isHighlighted: Bool {
        didSet {
            channelView.backgroundColor = isHighlighted ? uiConfig.colorPalette.highlightedBackground :
                uiConfig.colorPalette.background
        }
    }

    override internal func setUpLayout() {
        super.setUpLayout()
        contentView.embed(channelView)
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
