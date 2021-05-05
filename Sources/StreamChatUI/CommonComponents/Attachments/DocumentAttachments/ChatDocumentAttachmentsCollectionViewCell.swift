//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatDocumentAttachmentsCollectionViewCell =
    _ChatDocumentAttachmentsCollectionViewCell<NoExtraData>

open class _ChatDocumentAttachmentsCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell,
    ComponentsProvider {
    // MARK: - Properties
    
    class var reuseId: String { String(describing: self) }
    
    // MARK: - Subviews
    
    public private(set) lazy var documentAttachmentView = components
        .messageComposer
        .documentAttachmentView.init()
        .withoutAutoresizingMaskConstraints

    // MARK: - Public
    
    override open func setUpLayout() {
        contentView.embed(documentAttachmentView)
    }
        
    // MARK: - UICollectionViewLayoutAttributes
    
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
