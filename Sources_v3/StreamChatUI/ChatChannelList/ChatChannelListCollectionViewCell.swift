//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

open class ChatChannelListCollectionViewCell<ExtraData: UIExtraDataTypes>: UICollectionViewCell {
    
    // MARK: - Properties
    
    var uiConfig: UIConfig<ExtraData> = .default
    
    public private(set) lazy var channelView: ChatChannelView<ExtraData> = {
        let view = uiConfig.channelList.channelView.init(uiConfig: uiConfig)
        contentView.embed(view)
        return view
    }()
    
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
