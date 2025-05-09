//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The `ListCollectionViewLayout` delegate to control how to display the list.
public protocol ListCollectionViewLayoutDelegate: UICollectionViewDelegate {
    /// Implement this method to have detailed control over the visibility of the cell separators.
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: ListCollectionViewLayout,
        shouldShowSeparatorForCellAtIndexPath indexPath: IndexPath
    ) -> Bool
}

/// An `UICollectionViewFlowLayout` implementation to make the collection view behave as a `UITableView`.
open class ListCollectionViewLayout: UICollectionViewFlowLayout {
    /// The kind identifier of the cell separator view.
    open class var separatorKind: String {
        "CellSeparator"
    }

    /// The height of the cell separator view. This changes the `minimumLineSpacing` to properly display the separator height.
    /// By default it is the hair height, one physical pixel (1 / displayScale). If a value is set, it will change the default.
    /// The changes will apply after the layout it has been invalidated.
    open var separatorHeight: CGFloat?

    override open func prepare() {
        super.prepare()

        let defaultSeparatorHeight = 1 / (collectionView?.traitCollection.displayScale ?? 1)
        minimumLineSpacing = separatorHeight ?? defaultSeparatorHeight

        // We should always propose the full width of the collection view for the cell width
        estimatedItemSize = .init(
            width: collectionView?.bounds.width ?? 0,
            height: estimatedItemSize.height
        )
    }

    /// Partly taken from: https://github.com/Instagram/IGListKit/issues/571#issuecomment-386960195
    override open func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        if let indexPaths = context.invalidatedItemIndexPaths {
            context.invalidateSupplementaryElements(
                ofKind: Self.separatorKind,
                at: indexPaths
            )
        }
        super.invalidateLayout(with: context)
    }

    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let cellAttributes = super.layoutAttributesForElements(in: rect) ?? []
        let separatorAttributes = separatorLayoutAttributes(forCellLayoutAttributes: cellAttributes)
        return cellAttributes + separatorAttributes
    }
    
    override open func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard elementKind == Self.separatorKind else { return nil }
        guard let collectionView else { return nil }
        guard collectionView.numberOfItems(inSection: indexPath.section) > indexPath.row else { return nil }
        let cellFrame = layoutAttributesForItem(at: indexPath)?.frame ?? CGRect(x: 0, y: 0, width: collectionViewContentSize.width, height: 0)
        return separatorLayoutAttributes(forCellFrame: cellFrame, indexPath: indexPath)
    }

    private func separatorLayoutAttributes(forCellFrame cellFrame: CGRect, indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView else { return nil }
        let delegate = collectionView.delegate as? ListCollectionViewLayoutDelegate
        guard delegate?.collectionView(
            collectionView,
            layout: self,
            shouldShowSeparatorForCellAtIndexPath: indexPath
        ) ?? true else { return nil }
        let separatorAttribute = UICollectionViewLayoutAttributes(
            forSupplementaryViewOfKind: Self.separatorKind,
            with: indexPath
        )
        separatorAttribute.frame = CGRect(
            x: cellFrame.origin.x,
            y: cellFrame.origin.y + cellFrame.size.height,
            width: cellFrame.size.width,
            height: minimumLineSpacing
        )
        return separatorAttribute
    }
    
    private func separatorLayoutAttributes(
        forCellLayoutAttributes cellAttributes: [UICollectionViewLayoutAttributes]
    ) -> [UICollectionViewLayoutAttributes] {
        guard let collectionView = collectionView else { return [] }
        let delegate = collectionView.delegate as? ListCollectionViewLayoutDelegate
        return cellAttributes.compactMap { cellAttribute in
            guard cellAttribute.representedElementCategory == .cell else { return nil }
            return separatorLayoutAttributes(forCellFrame: cellAttribute.frame, indexPath: cellAttribute.indexPath)
        }
    }
}
