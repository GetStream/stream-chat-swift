//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageComposerDocumentAttachmentCollectionViewCell =
    _ChatMessageComposerDocumentAttachmentCollectionViewCell<NoExtraData>

internal class _ChatMessageComposerDocumentAttachmentCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell,
    UIConfigProvider {
    // MARK: - Properties
    
    class var reuseId: String { String(describing: self) }
    
    // MARK: - Subviews
    
    internal private(set) lazy var documentAttachmentView = uiConfig
        .messageComposer
        .documentAttachmentView.init()
        .withoutAutoresizingMaskConstraints

    // MARK: - internal
    
    override internal func setUpLayout() {
        contentView.embed(documentAttachmentView)
    }
        
    // MARK: - UICollectionViewLayoutAttributes
    
    override internal func preferredLayoutAttributesFitting(
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
