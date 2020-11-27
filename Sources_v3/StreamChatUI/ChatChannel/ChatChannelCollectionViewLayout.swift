//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

open class ChatChannelCollectionViewLayout: UICollectionViewFlowLayout {
    // MARK: - Init & Deinit
    
    override public init() {
        super.init()
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        minimumInteritemSpacing = 0
        minimumLineSpacing = 4
    }
    
    // MARK: - Overrides
    
    override open func prepare() {
        super.prepare()
        
        estimatedItemSize = .init(
            width: collectionView?.bounds.width ?? 0,
            height: 60
        )
        if collectionView!.contentSize == .zero {
            let newOffset = CGPoint(x: 0, y: collectionViewContentSize.height)
            collectionView?.contentOffset = newOffset
        }
    }

    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let contentSize = collectionViewContentSize
        let portalRect = CGRect(
            x: rect.origin.x,
            y: contentSize.height - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
        return super.layoutAttributesForElements(in: portalRect)?
            .map(flip(_:))
    }

    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        super.layoutAttributesForItem(at: indexPath).map(flip(_:))
    }

    private func flip(_ attribute: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let contentSize = collectionViewContentSize
        attribute.frame = CGRect(
            x: attribute.frame.origin.x,
            y: contentSize.height - attribute.frame.origin.y - attribute.frame.height,
            width: attribute.frame.width,
            height: attribute.frame.height
        )
        return attribute
    }
}
