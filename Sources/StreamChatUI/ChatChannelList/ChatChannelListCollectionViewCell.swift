//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

open class ChatChannelListCollectionViewCell<ExtraData: ExtraDataTypes>: CollectionViewCell, UIConfigProvider {
    // MARK: - Properties

    public private(set) lazy var channelView: ChatChannelListItemView<ExtraData> = uiConfig.channelList.channelListItemView.init()

    // MARK: - UICollectionViewCell

    override public func prepareForReuse() {
        super.prepareForReuse()
        channelView.trailingConstraint?.constant = 0
    }

    // MARK: Customizable

    override open func setUpLayout() {
        super.setUpLayout()
        contentView.embed(channelView)
    }

    // MARK: - Layout
    
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
